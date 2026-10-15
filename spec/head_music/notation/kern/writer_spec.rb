require "spec_helper"

describe HeadMusic::Notation::Kern::Writer do
  # Columns are separated by two or more spaces, so that chords can keep
  # their single spaces.
  def kern(text)
    text.gsub(/ {2,}/, "\t")
  end

  def parse(text)
    HeadMusic::Notation::Kern.parse(kern(text))
  end

  def render(flow, **options)
    described_class.new(flow, **options).to_s
  end

  def body(flow)
    render(flow).lines.map(&:chomp).drop_while { |line| !line.start_with?("=") }
  end

  def length_of(voice_event)
    [voice_event.position.to_s, voice_event.pitches.map(&:to_s), voice_event.rhythmic_value.total_value]
  end

  def music_of(flow)
    flow.to_h.except("work").merge("parts" => flow.to_h["parts"].map { |part| part.except("staff_system") })
  end

  def two_part_flow(name: "Duet")
    HeadMusic::Content::Flow.new(name: name, key_signature: "G major", meter: "4/4").tap do |flow|
      flow.add_voice.tap do |upper|
        upper.place("1:1", :half, "B4")
        upper.place("1:3", :half, "C5")
        upper.place("2:1", :whole, "B4")
      end
      flow.add_voice.tap do |lower|
        lower.place("1:1", :whole, "G3")
        lower.place("2:1", :whole, "G3")
      end
    end
  end

  describe "a two-voice flow" do
    subject(:output) { render(two_part_flow) }

    let(:expected) do
      kern(<<~KERN)
        !!!OTL: Duet
        **kern  **kern
        *clefF4  *clefG2
        *k[f#]  *k[f#]
        *G:  *G:
        *M4/4  *M4/4
        *MM120  *MM120
        =1-  =1-
        1G  2b
        .  2cc
        =2  =2
        1G  1b
        ==  ==
        *-  *-
      KERN
    end

    it "writes the whole document" do
      expect(output).to eq expected
    end

    it "reads back as the flow it was written from, citing a work by its title" do
      expect(HeadMusic::Notation::Kern.parse(output).to_h.except("parts", "work"))
        .to eq two_part_flow.to_h.except("parts", "work")
    end
  end

  describe "the story's example" do
    let(:source) do
      kern(<<~KERN)
        **kern  **kern
        *M4/4  *M4/4
        *k[]  *k[]
        =1  =1
        2C  2e
        2G  2d
        =2  =2
        1C  1c
        ==  ==
        *-  *-
      KERN
    end

    let(:expected) do
      kern(<<~KERN).lines.map(&:chomp)
        =1-  =1-
        2C  2e
        2G  2d
        =2  =2
        1C  1c
        ==  ==
        *-  *-
      KERN
    end

    it "writes the same spines back, the opening barline invisible" do
      expect(body(HeadMusic::Notation::Kern.parse(source))).to eq expected
    end
  end

  describe "reference records" do
    let(:flow) { two_part_flow(name: "Aus meines Herzens Grunde") }

    it "writes the name as the title, and a composer string as the composer" do
      flow = HeadMusic::Content::Flow.new(name: "Chorale", composer: "Anonymous")
      flow.add_voice.place("1:1", :whole, "C4")
      expect(render(flow).lines.first(2)).to eq ["!!!COM: Anonymous\n", "!!!OTL: Chorale\n"]
    end

    it "leaves out the title of a flow with the default name and no work" do
      flow = HeadMusic::Content::Flow.new
      flow.add_voice.place("1:1", :whole, "C4")
      expect(render(flow)).not_to include "!!!OTL"
    end

    it "reads a file with neither a title nor a work back to itself" do
      flow = parse("**kern\n*clefG2\n*M4/4\n=1\n1c\n==\n*-")
      expect(HeadMusic::Notation::Kern.parse(render(flow)).to_h).to eq flow.to_h
    end

    it "writes each name of a composer string that holds several as its own record" do
      flow = parse("!!!COM: Bach, J. S.\n!!!COM: Handel, G. F.\n**kern\n*clefG2\n*M4/4\n=1\n1c\n==\n*-")
      expect(render(flow).lines.grep(/COM/).map(&:chomp)).to eq ["!!!COM: J. S. Bach", "!!!COM: G. F. Handel"]
    end

    it "reads several composers of a file with no title back to themselves" do
      flow = parse("!!!COM: Bach, J. S.\n!!!COM: Handel, G. F.\n**kern\n*clefG2\n*M4/4\n=1\n1c\n==\n*-")
      expect(HeadMusic::Notation::Kern.parse(render(flow)).composer).to eq "J. S. Bach, G. F. Handel"
    end

    context "when the flow cites a work" do
      before do
        bach = HeadMusic::Content::Person.new(
          full_name: "Johann Sebastian Bach", sort_name: "Bach, Johann Sebastian", birth_year: 1685, death_year: 1750
        )
        flow.work = HeadMusic::Content::Work.new(title: "Chorale", catalog_number: "BWV 269", year: 1731)
          .with_credit(bach, :composer)
      end

      it "writes the composer's sort name, lifespan, the title, catalog number, and date" do
        expect(render(flow).lines.first(5).map(&:chomp)).to eq [
          "!!!COM: Bach, Johann Sebastian", "!!!CDT: 1685/-1750/", "!!!OTL: Aus meines Herzens Grunde",
          "!!!SCT: BWV 269", "!!!ODT: 1731"
        ]
      end

      it "reads back the work" do
        work = HeadMusic::Notation::Kern.parse(render(flow)).work
        expect([work.catalog_number, work.year, work.credits.for(:composer).map { |credit| credit.person.to_h }])
          .to eq ["BWV 269", 1731, [flow.work.credits.for(:composer).first.person.to_h]]
      end

      it "leaves out the lifespan when the work has more than one composer" do
        flow.work = flow.work.with_credit(HeadMusic::Content::Person.new(full_name: "C. P. E. Bach"), :composer)
        expect(render(flow)).not_to include "!!!CDT"
      end
    end
  end

  describe "notes, rests, chords, and ties" do
    subject(:flow) do
      HeadMusic::Content::Flow.new(meter: "4/4").tap do |flow|
        voice = flow.add_voice
        voice.place("1:1", :quarter, %w[C4 E4 G4])
        voice.place("1:2", :quarter)
        voice.place("1:3", HeadMusic::Rudiment::RhythmicValue.get("dotted half"), "F#5")
        voice.place("2:2", HeadMusic::Rudiment::RhythmicValue.get("dotted half"), "Bb2")
      end
    end

    it "writes a chord as space-separated notes, a rest, and a note crossing a barline as tied notes" do
      expect(body(flow).first(8)).to eq ["=1-", "4c 4e 4g", "4r", "[2ff#", "=2", "4ff#]", "2.BB-", "=="]
    end

    it "reads the tied note back as one voice event of the same length" do
      expect(HeadMusic::Notation::Kern.parse(render(flow)).voices.first.voice_events.map { |voice_event| length_of(voice_event) })
        .to eq flow.voices.first.voice_events.map { |voice_event| length_of(voice_event) }
    end
  end

  describe "tuplets" do
    def value(name, tuplet)
      HeadMusic::Rudiment::RhythmicValue.get(name, tuplet: tuplet)
    end

    def data(flow)
      render(flow).lines.map(&:chomp).grep(/\A[^*!=]/)
    end

    it "writes a septuplet at its exact onsets, though its positions round, with a level at one of them" do
      flow = HeadMusic::Content::Flow.new(meter: "2/4")
      voice = TupletFixtures.fill(flow.add_voice, TupletFixtures.run("7:4", :sixteenth, %w[C4 D4 E4 F4 G4 A4 B4]) + [[:quarter, "C5"]])
      voice.part.place_dynamic(voice.voice_events[3].position, :p)
      expect(data(flow)).to eq ["28c\t.", "28d\t.", "28e\t.", "28f\tp", "28g\t.", "28a\t.", "28b\t.", "4cc\t."]
    end

    it "writes a triplet quarter crossing the barline as tied triplet eighths" do
      flow = TupletFixtures.tuplet_crossing_barline
      expect(body(flow).first(8)).to eq ["=1-", "2.c", "6d", "[12e", "=2", "12e]", "6f", "2.g"]
    end

    it "pads a voice that ends after a lone triplet with rests kern reads under its ratio" do
      flow = HeadMusic::Content::Flow.new(meter: "2/4")
      flow.add_voice.place("1:1", :half, "C4")
      short = flow.add_voice
      short.place("1:1", value(:eighth, "3:2"), "E4")
      expect(data(flow)).to eq ["12e\t2c", "3r\t.", "12r\t."]
    end
  end

  describe "grace notes" do
    def data(flow)
      render(flow).lines.map(&:chomp).grep(/\A[^*!=]/)
    end

    it "writes each grace note as a token of its own, slashed as q and unslashed as Q, with a tie and a slur" do
      expect(data(TupletFixtures.grace_notes_before_downbeat)).to eq [
        "4c", "4e", "16aQ 16ccQ", "4g", "16g'Q", "4f", "8fq", "1e", "(16dQ", "16c[Q", "1c])"
      ]
    end

    it "writes each spine's grace notes on the rows before its note, the last beside the note" do
      flow = HeadMusic::Content::Flow.new(meter: "2/4")
      flow.add_voice.place("1:1", :half, "E5").add_grace_note("F5", :sixteenth).add_grace_note("G5", :sixteenth)
      flow.add_voice.place("1:1", :half, "C4").add_grace_note("D4", :eighth, slashed: true)
      expect(data(flow)).to eq [".\t16ffQ", "8dq\t16ggQ", "2c\t2ee"]
    end

    it "continues a tie into a note that is itself tied onward" do
      flow = HeadMusic::Content::Flow.new(meter: "2/4")
      flow.add_voice.place("1:1", :whole, "C4").add_grace_note("C4", :sixteenth, tied: true)
      expect(data(flow)).to eq ["16c[Q", "2c_", "2c]"]
    end

    {
      "outlasts a slur ending on its note" => [["1:1", "1:3"], ["1:3", "1:4", true]],
      "nests inside a slur ending on its note" => [["1:1", "1:3"], ["1:3", "1:3", true]],
      "outlasts a slur starting on its note" => [["1:3", "1:4", true], ["1:3", "2:1"]]
    }.each do |label, spans|
      it "reads back a slur from grace notes that #{label}" do
        flow = MarkingFixtures.four_quarters
        voice = flow.voices.first
        %w[1:3 1:4].each { |position| voice.voice_event_at(position).add_grace_note("B4", :sixteenth) }
        spans.each { |from, to, from_grace| voice.add_span(:slur, from: from, to: to, from_grace: from_grace || false) }
        expect_same_spans(flow, HeadMusic::Notation::Kern.parse(render(flow)))
      end
    end

    it "raises for an unpitched grace note" do
      flow = HeadMusic::Content::Flow.new(meter: "2/4")
      flow.add_voice.place("1:1", :half, "C4").add_grace_note(HeadMusic::Rudiment::UnpitchedSound.get(:snare_drum), :sixteenth)
      expect { render(flow) }.to raise_error(HeadMusic::Notation::Kern::RenderError, /unpitched grace note .* before 1:1:000/)
    end
  end

  describe "token markings" do
    subject(:flow) do
      HeadMusic::Content::Flow.new(meter: "4/4").tap do |flow|
        voice = flow.add_voice
        voice.place("1:1", :quarter, %w[C4 E4]).articulate(:staccato, :accent).embellish(:trill)
        voice.place("1:2", :quarter, "D4").articulate(:tenuto, :staccatissimo, :marcato).note_dynamic = :sfz
        voice.place("1:3", :half, "E4").embellish(:mordent, :inverted_mordent, :turn)
        voice.place("2:1", HeadMusic::Rudiment::RhythmicValue.get("dotted whole"), "F4").articulate(:accent)
      end
    end

    it "writes each marking after the pitch, on every note of a chord and only on a tie's first link" do
      expect(body(flow).first(7)).to eq ["=1-", "4c^'T 4e^'T", "4d^^`~z", "2eMWS", "=2", "[1f^", "=3"]
    end

    it "reads the markings back" do
      expect_same_markings(flow, HeadMusic::Notation::Kern.parse(render(flow)))
    end
  end

  describe "dynamics" do
    let(:flow) { HeadMusic::Content::Flow.new(meter: "4/4") }
    let(:voice) { flow.add_voice }
    let(:part) { voice.part }

    def data(flow)
      render(flow).lines.map(&:chomp).grep(/\A[^*!=]/)
    end

    it "writes a **dynam spine after the part's rightmost spine" do
      voice.place("1:1", :whole, "C4")
      part.place_dynamic("1:1", :p)
      expect(render(flow).lines.map(&:chomp).grep(/\A\*\*/)).to eq ["**kern\t**dynam"]
    end

    it "writes no **dynam spine for a part with only sfz, which its tokens carry" do
      voice.place("1:1", :whole, "C4").note_dynamic = :sfz
      expect(render(flow)).not_to include "**dynam"
    end

    it "writes sf, rfz, and fp in the **dynam spine, and sfz in the token" do
      %i[sf rfz fp sfz].each_with_index { |accent, index| voice.place("1:#{index + 1}", :quarter, "C4").note_dynamic = accent }
      expect(data(flow)).to eq ["4c\tsf", "4c\trfz", "4c\tfp", "4cz\t."]
    end

    # A level left out can often be told from the levels around it; an accent
    # left out is gone.
    it "writes an accent over a level, and the part's and a voice's same level once" do
      voice.place("1:1", :half, "C4").note_dynamic = :sf
      voice.place("1:3", :half, "D4")
      [part, voice].each { |owner| %w[1:1 1:3].zip(%w[f mf]) { |position, level| owner.place_dynamic(position, level) } }
      expect(data(flow)).to eq ["2c\tsf", "2d\tmf"]
    end

    it "refuses the part's and a voice's different levels at one position" do
      voice.place("1:1", :whole, "C4")
      part.place_dynamic("1:3", :f)
      voice.place_dynamic("1:3", :p)
      expect { data(flow) }.to raise_error(HeadMusic::Notation::Kern::RenderError, /\*\*dynam spine holds one dynamic at a time, so the f and the p at 1:3:000/)
    end

    it "refuses two voices' different levels at one position" do
      voice.place("1:1", :whole, "C4")
      part.add_voice.tap { |lower| lower.place("1:1", :whole, "C3") }.place_dynamic("1:1", :pp)
      voice.place_dynamic("1:1", :ff)
      expect { data(flow) }.to raise_error(HeadMusic::Notation::Kern::RenderError, /the ff and the pp at 1:1:000/)
    end

    it "keeps an fp over a level at its note, so the level in force reads back the same" do
      voice.place("1:1", :half, "C4").note_dynamic = :fp
      voice.place("1:3", :half, "D4")
      part.place_dynamic("1:1", :f)
      restored = HeadMusic::Notation::Kern.parse(render(flow)).voices.first
      expect(%w[1:1 1:3].map { |position| restored.dynamic_at(position).name_key }).to eq %w[p p]
    end

    it "writes a dynamic in the middle of the part's notes on a null row, leaving the notes whole" do
      voice.place("1:1", :whole, "C4")
      part.place_dynamic("1:3", :mf)
      expect(data(flow)).to eq ["1c\t.", ".\tmf"]
    end

    it "spaces null rows evenly to land on each dynamic in a note or rest" do
      voice.place("1:1", :whole, "C4")
      voice.place("2:1", :whole)
      {"1:2" => :p, "1:3" => :f, "2:3" => :pp}.each { |position, level| part.place_dynamic(position, level) }
      expect(data(flow)).to eq ["1c\t.", ".\tp", ".\tf", ".\t.", "1r\t.", ".\tpp"]
    end

    it "leaves a note whole where another part attacks at its dynamic" do
      voice.place("1:1", :whole, "C4")
      flow.add_voice.tap { |upper| (1..4).each { |count| upper.place("1:#{count}", :quarter, "E5") } }
      part.place_dynamic("1:3", :mf)
      expect(data(flow)).to eq ["4ee\t1c\t.", "4ee\t.\t.", "4ee\t.\tmf", "4ee\t.\t."]
    end

    it "refuses a dynamic after the music ends" do
      voice.place("1:1", :whole, "C4")
      part.place_dynamic("2:1", :f)
      expect { data(flow) }.to raise_error(HeadMusic::Notation::Kern::RenderError, /dynamic f at 2:1:000 falls after/)
    end

    it "writes a dynamic after the music's end on an invisible rest that fills the final bar" do
      %w[C4 D4 E4].each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch) }
      voice.place_dynamic("1:4", :f)
      expect(data(flow)).to eq ["4c\t.", "4d\t.", "4e\t.", "4ryy\tf"]
    end

    it "writes a dynamic between the timed rows after the music's end on a null row" do
      voice.place("1:1", :half, "C4")
      part.place_dynamic("1:4", :f)
      expect(data(flow)).to eq ["2c\t.", "2ryy\t.", ".\tf"]
    end

    it "fills every kern spine of every part past the music's end with invisible rests" do
      voice.place("1:1", :half, "C4")
      flow.add_voice.place("1:1", :quarter, "E5")
      part.place_dynamic("1:3", :f)
      expect(data(flow)).to eq ["4ee\t2c\t.", "4r\t.\t.", "2ryy\t2ryy\tf"]
    end

    it "writes a pickup's leading rest to hold a dynamic before the pickup's first note" do
      voice.place("0:1", :half)
      voice.place("0:3", :half, "C4")
      voice.place("1:1", :whole, "D4")
      part.place_dynamic("0:2", :p)
      expect(data(flow)).to eq ["2r\t.", ".\tp", "2c\t.", "1d\t."]
    end

    it "writes a pickup bar of rest to hold a dynamic in it" do
      voice.place("0:1", :whole)
      voice.place("1:1", :whole, "D4")
      part.place_dynamic("0:3", :p)
      expect(data(flow)).to eq ["1r\t.", ".\tp", "1d\t."]
    end

    it "starts a pickup at its first note when the dynamic falls on that note" do
      voice.place("0:1", :half)
      voice.place("0:3", :half, "C4")
      voice.place("1:1", :whole, "D4")
      part.place_dynamic("0:3", :p)
      expect(data(flow)).to eq ["2c\tp", "1d\t."]
    end

    it "writes the note whole under a dynamic at any offset" do
      voice.place("1:1", :whole, "C4")
      part.place_dynamic("1:1:320", :f)
      expect(data(flow)).to eq ["1c\t.", ".\tf", *Array.new(10, ".\t.")]
    end

    # One null row per tick of the span at most, since positions resolve no
    # finer than a tick.
    it "writes a null row per tick under a dynamic one tick into a whole note" do
      voice.place("1:1", :whole, "C4")
      part.place_dynamic("1:1:001", :f)
      expect(data(flow).length).to eq 3840
    end
  end

  describe "a pickup" do
    subject(:flow) do
      parse(<<~KERN)
        **kern
        *M3/4
        4c
        =1
        2.d
        =2
        2e
        ==
        *-
      KERN
    end

    it "leaves out the pickup's leading rest, and the final bar stays short" do
      expect(body(flow).unshift(render(flow).lines.map(&:chomp).grep(/\A4c/).first))
        .to eq ["4c", "=1", "2.d", "=2", "2e", "==", "*-"]
    end

    it "reads back as the same flow" do
      expect(music_of(HeadMusic::Notation::Kern.parse(render(flow)))).to eq music_of(flow)
    end
  end

  describe "repeats" do
    subject(:flow) do
      parse(<<~KERN)
        **kern
        *M2/4
        =1!|:
        2c
        =2
        2d
        =3:|!|:
        2e
        ==:|!
        *-
      KERN
    end

    it "writes repeat barlines" do
      expect(body(flow)).to eq ["=1!|:", "2c", "=2", "2d", "=3:|!|:", "2e", "==:|!", "*-"]
    end

    it "writes a repeat sign in place of a double or final barline" do
      flow.bars(2).last.barline = :double
      flow.bars(3).last.barline = :final
      expect(body(flow)).to eq ["=1!|:", "2c", "=2", "2d", "=3:|!|:", "2e", "==:|!", "*-"]
    end
  end

  describe "bar markings" do
    subject(:flow) do
      HeadMusic::Content::Flow.new(meter: "2/4").tap do |marked|
        voice = marked.add_voice
        %w[C4 D4 E4 F4 G4].each_with_index { |pitch, index| voice.place("#{index + 1}:1", :half, pitch) }
        marked.add_voice.place("1:1", :half, "C3").sing("la", verse: 1)
      end
    end

    def bar(number)
      flow.bars(number).last
    end

    it "writes a double barline and a final barline in the middle of the flow" do
      bar(1).barline = :double
      bar(2).barline = :final
      expect(body(flow).grep(/\A=/)).to eq ["=1-\t=1-\t=1-", "=2||\t=2||\t=2||", "=3|!\t=3|!\t=3|!", "=4\t=4\t=4", "=5\t=5\t=5", "==\t==\t=="]
    end

    it "writes a dashed or dotted barline as a regular one" do
      bar(1).barline = :dashed
      bar(2).barline = :dotted
      expect(body(flow).grep(/\A=[23]/)).to eq ["=2\t=2\t=2", "=3\t=3\t=3"]
    end

    it "writes == at the end whatever the last bar's style" do
      bar(5).barline = :double
      expect(body(flow).grep(/\A==/)).to eq ["==\t==\t=="]
    end

    it "writes a rehearsal mark as a section label across every spine after its barline" do
      bar(3).rehearsal_mark = "B"
      expect(body(flow).each_cons(2).find { |_barline, row| row.start_with?("*>") }).to eq ["=3\t=3\t=3", "*>B\t*>B\t*>B"]
    end

    it "writes the first bar's rehearsal mark among the opening interpretations" do
      bar(1).rehearsal_mark = "A"
      expect(render(flow).lines.map(&:chomp).take_while { |line| !line.start_with?("=") }).to include("*>A\t*>A\t*>A")
    end

    it "keeps a mark's spaces, and writes its brackets as parentheses so it is not an expansion list" do
      bar(2).rehearsal_mark = "Verse [2]\tagain"
      expect(body(flow)).to include("*>Verse (2) again\t*>Verse (2) again\t*>Verse (2) again")
    end
  end

  describe "changes in the middle of the flow" do
    subject(:flow) do
      parse(<<~KERN)
        **kern  **kern
        *clefF4  *clefG2
        *k[]  *k[]
        *C:  *C:
        *M4/4  *M4/4
        *MM90  *MM90
        =1  =1
        1C  1c
        =2  =2
        *clefG2  *
        *k[b-]  *k[b-]
        *F:  *F:
        *M3/4  *M3/4
        *MM60  *MM60
        2.c  2.f
        ==  ==
        *-  *-
      KERN
    end

    let(:expected) do
      kern(<<~KERN).lines.map(&:chomp)
        =1-  =1-
        1C  1c
        =2  =2
        *clefG2  *
        *k[b-]  *k[b-]
        *F:  *F:
        *M3/4  *M3/4
        *MM60  *MM60
        2.c  2.f
        ==  ==
        *-  *-
      KERN
    end

    it "writes each change after its barline" do
      expect(body(flow)).to eq expected
    end

    it "reads back as the same flow" do
      expect(music_of(HeadMusic::Notation::Kern.parse(render(flow)))).to eq music_of(flow)
    end
  end

  describe "voices of different lengths" do
    subject(:flow) do
      HeadMusic::Content::Flow.new(meter: "4/4").tap do |flow|
        flow.add_voice.place("1:1", :whole, "C5")
        flow.add_voice.tap do |lower|
          lower.place("2:1", :half, "C3")
          lower.place("2:3", :half, "G2")
        end
      end
    end

    it "pads the shorter voices with rests" do
      expect(body(flow).first(6)).to eq ["=1-\t=1-", "1r\t1cc", "=2\t=2", "2C\t1r", "2GG\t.", "==\t=="]
    end
  end

  describe "players and instruments" do
    subject(:flow) do
      parse(<<~KERN)
        **kern  **kern
        *Ibass  *Isoprn
        *I"Bass  *I"Soprano
        =1  =1
        1C  1cc
        ==  ==
        *-  *-
      KERN
    end

    it "writes each part's instrument code and player name" do
      expect(render(flow)).to include(kern("*Ibass  *Isoprn\n*I\"Bass  *I\"Soprano\n"))
    end

    it "writes a player shared by two parts on both spines" do
      flow.parts.last.player = flow.parts.first.player
      expect(render(flow)).to include(kern("*I\"Soprano  *I\"Soprano\n"))
    end
  end

  describe "parts with several voices or staves" do
    let(:grand_staff) { HeadMusic::Content::StaffSystem.grand_staff }
    let(:flow) do
      HeadMusic::Content::Flow.new(meter: "4/4").tap do |flow|
        piano = flow.add_part(instrument: "piano", staff_system: grand_staff)
        piano.add_voice.tap do |upper|
          upper.place("1:1", :whole, "E5")
          upper.place("2:1", :whole, "D5")
        end
        piano.add_voice.tap do |inner|
          inner.place("1:1", :whole, "C5")
          inner.place("2:1", :whole, "B4")
        end
        piano.add_voice.tap do |left_hand|
          left_hand.assign_staff(1, grand_staff.staves.last)
          left_hand.place("1:1", :whole, "C3")
          left_hand.place("2:1", :whole, "G4")
          left_hand.assign_staff(2, grand_staff.staves.first)
        end
      end
    end
    let(:restored) { HeadMusic::Notation::Kern.parse(render(flow)) }

    it "tags every spine with its part and its staff, numbered top-down" do
      expect(render(flow).lines.grep(/\A\*(part|staff)/).first(2).map(&:chomp))
        .to eq ["*part1\t*part1\t*part1", "*staff2\t*staff1\t*staff1"]
    end

    it "writes a staff crossing after its barline" do
      expect(body(flow)[2..3]).to eq ["=2\t=2\t=2", "*staff1\t*\t*"]
    end

    it "reads back one part on two staves" do
      expect([restored.parts.length, restored.parts.first.staff_system.length]).to eq [1, 2]
    end

    it "reads back each voice's staff at each bar" do
      staves = restored.parts.first.staff_system.staves
      expect(restored.voices.map { |voice| [staves.index(voice.staff_at(1)), staves.index(voice.staff_at(2))] })
        .to eq [[0, 0], [0, 0], [1, 0]]
    end

    context "when the staff a voice crosses to changes its clef in the same bar" do
      before { grand_staff.staves.first.change_clef(2, HeadMusic::Rudiment::Clef.get("alto_clef")) }

      it "writes the crossing before the clef" do
        expect(body(flow)[3..4]).to eq ["*staff1\t*\t*", "*clefC3\t*clefC3\t*clefC3"]
      end

      it "reads back the clef change on that staff alone" do
        expect(restored.parts.first.staff_system.staves.map { |staff| staff.clef_at(2).name_key })
          .to eq %w[alto_clef bass_clef]
      end
    end

    it "reads back the voices in order" do
      expect(restored.voices.map { |voice| voice.voice_events.map(&:to_s) })
        .to eq flow.voices.map { |voice| voice.voice_events.map(&:to_s) }
    end
  end

  describe "lyrics" do
    subject(:flow) do
      HeadMusic::Content::Flow.new(meter: "4/4").tap do |flow|
        melody = flow.add_voice
        melody.place("1:1", :half, "C5").sing("Aus", verse: 1).sing("Fear", verse: 2)
        melody.place("1:3", :half, "D5").sing("mei", verse: 1, hyphen_after: true)
        melody.place("2:1", :whole, "E5").sing("nes", verse: 1).sing("not", verse: 2)
        flow.add_voice.place("1:1", HeadMusic::Rudiment::RhythmicValue.get("double whole"), "C3")
      end
    end

    let(:expected) do
      kern(<<~KERN).lines.map(&:chomp)
        =1-  =1-  =1-  =1-
        [1C  2cc  Aus  Fear
        .  2dd  mei-  .
        =2  =2  =2  =2
        1C]  1ee  -nes  not
      KERN
    end

    it "writes a text spine for each verse beside the sung voice" do
      expect(render(flow).lines.grep(/\*\*/).first).to eq "**kern\t**kern\t**text\t**text\n"
    end

    it "hyphenates a word across its notes" do
      expect(body(flow).first(5)).to eq expected
    end

    it "reads the syllables back" do
      restored = HeadMusic::Notation::Kern.parse(render(flow))
      expect(restored.voices.first.voice_events.map { |voice_event| voice_event.syllables.transform_values(&:to_h) })
        .to eq flow.voices.first.voice_events.map { |voice_event| voice_event.syllables.transform_values(&:to_h) }
    end
  end

  describe "errors" do
    it "refuses a flow with no voices" do
      expect { render(HeadMusic::Content::Flow.new) }
        .to raise_error HeadMusic::Notation::Kern::RenderError, /no voices/
    end

    it "refuses unpitched sounds" do
      flow = HeadMusic::Content::Flow.new
      flow.add_part(instrument: "snare_drum").add_voice.place("1:1", :whole, "snare_drum")
      expect { render(flow) }.to raise_error HeadMusic::Notation::Kern::RenderError, /unpitched/
    end

    it "refuses written pitch for a transposing part" do
      flow = HeadMusic::Content::Flow.new
      flow.add_part(instrument: "clarinet").add_voice.place("1:1", :whole, "C4")
      expect { render(flow, transposed: true) }
        .to raise_error HeadMusic::Notation::Kern::RenderError, /concert pitch/
    end

    it "writes a transposing part at concert pitch" do
      flow = HeadMusic::Content::Flow.new
      flow.add_part(instrument: "clarinet").add_voice.place("1:1", :whole, "C4")
      expect(body(flow)[1]).to eq "1c"
    end

    it "refuses an instrument change within a part" do
      flow = HeadMusic::Content::Flow.new
      part = flow.add_part(instrument: "flute")
      part.add_voice.place("1:1", :whole, "C5")
      part.change_instrument(2, "piccolo")
      expect { render(flow) }.to raise_error HeadMusic::Notation::Kern::RenderError, /instrument change/
    end

    it "refuses a staff system change within a part" do
      flow = HeadMusic::Content::Flow.new
      part = flow.add_part
      part.add_voice.place("1:1", :whole, "C5")
      part.change_staff_system(2, HeadMusic::Content::StaffSystem.grand_staff)
      expect { render(flow) }.to raise_error HeadMusic::Notation::Kern::RenderError, /staff system change/
    end

    it "refuses dynamics on a part with no voices" do
      flow = HeadMusic::Content::Flow.new
      flow.add_part.add_voice.place("1:1", :whole, "C5")
      flow.add_part.place_dynamic("1:1", :p)
      expect { render(flow) }.to raise_error HeadMusic::Notation::Kern::RenderError, /part with no voices/
    end
  end

  describe "hairpins" do
    let(:flow) { HeadMusic::Content::Flow.new(meter: "4/4") }
    let(:voice) { flow.add_voice }
    let(:part) { voice.part }

    def data(flow)
      render(flow).lines.map(&:chomp).grep(/\A[^*!=]/)
    end

    def quarters(*pitches)
      pitches.each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch) }
    end

    it "writes a part's hairpins in a **dynam spine of their own, opening at the start and closing at the end" do
      quarters("C4", "D4", "E4", "F4")
      part.add_span(:crescendo, from: "1:1", to: "1:2")
      part.add_span(:diminuendo, from: "1:3", to: "1:4")
      expect(data(flow)).to eq ["4c\t<", "4d\t[", "4e\t>", "4f\t]"]
    end

    it "writes a voice's hairpin in its part's spine" do
      quarters("C4", "D4")
      voice.add_span(:crescendo, from: "1:1", to: "1:2")
      expect(data(flow)).to eq ["4c\t<", "4d\t["]
    end

    it "writes closes, then the level, then opens in one field" do
      quarters("C4", "D4", "E4", "F4")
      part.place_dynamic("1:2", :p)
      [%w[diminuendo 1:1 1:2], %w[crescendo 1:2 1:3], %w[diminuendo 1:3 1:4]].each { |kind, from, to| part.add_span(kind, from: from, to: to) }
      expect(data(flow)).to eq ["4c\t>", "4d\t]p<", "4e\t[>", "4f\t]"]
    end

    it "cuts a hairpin into touching pieces at a level or spine accent inside it" do
      quarters("C4", "D4", "E4", "F4")
      voice.add_span(:crescendo, from: "1:1", to: "1:4")
      voice.place_dynamic("1:2", :mf)
      voice.voice_event_at(flow.position("1:3")).note_dynamic = :sf
      expect(data(flow)).to eq ["4c\t<", "4d\t[mf<", "4e\t[sf<", "4f\t["]
    end

    it "does not cut a hairpin at sfz, which the token carries" do
      quarters("C4", "D4", "E4")
      voice.add_span(:crescendo, from: "1:1", to: "1:3")
      voice.voice_event_at(flow.position("1:2")).note_dynamic = :sfz
      expect(data(flow)).to eq ["4c\t<", "4dz\t.", "4e\t["]
    end

    it "cuts a voice's hairpin at a level of its part" do
      quarters("C4", "D4", "E4")
      voice.add_span(:crescendo, from: "1:1", to: "1:3")
      part.place_dynamic("1:2", :p)
      expect(data(flow)).to eq ["4c\t<", "4d\t[p<", "4e\t["]
    end

    it "places marks inside a held note on null rows, leaving the note whole" do
      voice.place("1:1", :whole, "C4")
      voice.place("2:1", :whole, "D4")
      part.add_span(:crescendo, from: "1:2", to: "1:4")
      expect(data(flow)).to eq ["1c\t.", ".\t<", ".\t.", ".\t[", "1d\t."]
    end

    it "closes a hairpin ending on the final barline with a doubled close on the last row" do
      quarters("C4", "D4", "E4", "F4")
      part.add_span(:diminuendo, from: "1:2", to: "2:1")
      expect(data(flow)).to eq ["4c\t.", "4d\t>", "4e\t.", "4f\t]]"]
    end

    it "closes such a hairpin on one more null row when the last row opens it" do
      voice.place("1:1", :whole, "C4")
      part.add_span(:crescendo, from: "1:1", to: "2:1")
      expect(data(flow)).to eq ["1c\t<", ".\t[["]
    end

    it "keeps the null rows evenly spaced when it adds that row" do
      voice.place("1:1", :whole, "C4")
      part.place_dynamic("1:2", :p)
      part.add_span(:crescendo, from: "1:3", to: "2:1")
      expect(data(flow)).to eq ["1c\t.", ".\tp", ".\t<", ".\t[["]
    end

    it "keeps a short final bar short for a hairpin ending on the final barline" do
      quarters("C4", "D4", "E4")
      voice.add_span(:crescendo, from: "1:1", to: "2:1")
      expect(data(flow)).to eq ["4c\t<", "4d\t.", "4e\t[["]
    end

    it "fills a short final bar with invisible rest for a hairpin starting after the music" do
      quarters("C4", "D4", "E4")
      voice.add_span(:diminuendo, from: "1:4", to: "2:1")
      expect(data(flow)).to eq ["4c\t.", "4d\t.", "4e\t.", "4ryy\t>", ".\t]]"]
    end

    it "fills a short final bar for a hairpin ending where its music ends" do
      quarters("C4", "D4", "E4")
      voice.add_span(:crescendo, from: "1:1", to: "1:4")
      expect(data(flow)).to eq ["4c\t<", "4d\t.", "4e\t.", "4ryy\t["]
    end

    it "writes a pickup's leading rest to hold a hairpin starting before the pickup's first note" do
      voice.place("0:1", :half)
      voice.place("0:3", :half, "C4")
      voice.place("1:1", :whole, "D4")
      part.add_span(:crescendo, from: "0:2", to: "1:1")
      expect(data(flow)).to eq ["2r\t.", ".\t<", "2c\t.", "1d\t["]
    end

    it "writes the same hairpin from the part and a voice once" do
      quarters("C4", "D4")
      [part, voice].each { |owner| owner.add_span(:crescendo, from: "1:1", to: "1:2") }
      expect(data(flow)).to eq ["4c\t<", "4d\t["]
    end

    it "writes touching hairpins from different owners" do
      quarters("C4", "D4", "E4")
      part.add_span(:crescendo, from: "1:1", to: "1:2")
      voice.add_span(:diminuendo, from: "1:2", to: "1:3")
      expect(data(flow)).to eq ["4c\t<", "4d\t[>", "4e\t]"]
    end

    it "writes overlapping hairpins from different owners whose pieces a level makes the same" do
      quarters("C4", "D4", "E4")
      part.add_span(:crescendo, from: "1:1", to: "1:2")
      voice.add_span(:crescendo, from: "1:1", to: "1:3")
      voice.place_dynamic("1:2", :mf)
      expect(data(flow)).to eq ["4c\t<", "4d\t[mf<", "4e\t["]
    end

    it "refuses overlapping hairpins from different owners of one part, naming both" do
      %w[1:1 2:1].each { |position| voice.place(position, :whole, "C4") }
      part.add_span(:crescendo, from: "1:1", to: "2:1")
      voice.add_span(:diminuendo, from: "1:3", to: "2:3")
      expect { data(flow) }.to raise_error(HeadMusic::Notation::Kern::RenderError, "a part's **dynam spine holds one hairpin " \
        "at a time, so the crescendo from 1:1:000 to 2:1:000 and the diminuendo from 1:3:000 to 2:3:000 cannot both be written")
    end

    it "refuses overlapping hairpins from two voices of one part" do
      voice.place("1:1", :whole, "C4")
      part.add_voice.tap { |lower| lower.place("1:1", :whole, "C3") }.add_span(:crescendo, from: "1:1", to: "1:3")
      voice.add_span(:diminuendo, from: "1:2", to: "1:4")
      expect { data(flow) }.to raise_error(HeadMusic::Notation::Kern::RenderError, /one hairpin at a time/)
    end

    it "writes overlapping hairpins of different parts in their own spines" do
      voice.place("1:1", :whole, "C4")
      other = flow.add_voice.tap { |upper| upper.place("1:1", :whole, "E5") }
      part.add_span(:crescendo, from: "1:1", to: "1:3")
      other.add_span(:diminuendo, from: "1:2", to: "1:4")
      expect(data(flow)).to eq ["1ee\t.\t1c\t<", ".\t>\t.\t.", ".\t.\t.\t[", ".\t]\t.\t."]
    end

    it "refuses a hairpin of a part with no voices" do
      voice.place("1:1", :whole, "C4")
      flow.add_part.add_span(:crescendo, from: "1:1", to: "1:3")
      expect { data(flow) }.to raise_error(HeadMusic::Notation::Kern::RenderError, /dynamics of a part with no voices/)
    end
  end

  describe "slurs and phrases" do
    def spanned_tokens(flow)
      render(flow).lines.map(&:chomp).grep(/\A[^*!=]/).grep(/[(){}]/)
    end

    it "opens a slur on its first note and closes it on its last" do
      flow = MarkingFixtures.four_quarters.tap { |four| four.voices.first.add_span(:slur, from: "1:1", to: "1:3") }
      expect(spanned_tokens(flow)).to eq ["(4c", "4e)"]
    end

    it "closes a slur on the last link of a note tied across a barline" do
      expect(spanned_tokens(MarkingFixtures.spanned_melody)).to include("4cc])", "([4ff")
    end

    it "writes a phrase ending on a rest" do
      expect(spanned_tokens(MarkingFixtures.spanned_melody).last).to eq "2r}"
    end

    it "elides slurs that cross" do
      expect(spanned_tokens(MarkingFixtures.crossing_spans)).to eq ["(4c", "&(4d", "4e)", "4f&)"]
    end

    it "ends one slur and begins the next on one note" do
      expect(spanned_tokens(MarkingFixtures.touching_slurs)).to eq ["(4c", "(4e)", "1g)"]
    end

    it "marks a chord once" do
      flow = HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nM:4/4\nK:C\n[CE] D [EG] F|\n")
      flow.voices.first.add_span(:slur, from: "1:1", to: "1:3")
      expect(spanned_tokens(flow)).to eq ["(4c 4e", "4e) 4g"]
    end
  end
end
