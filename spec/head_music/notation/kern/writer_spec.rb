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

  def length_of(placement)
    [placement.position.to_s, placement.pitches.map(&:to_s), placement.rhythmic_value.total_value]
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

    it "reads the tied note back as one placement of the same length" do
      expect(HeadMusic::Notation::Kern.parse(render(flow)).voices.first.placements.map { |placement| length_of(placement) })
        .to eq flow.voices.first.placements.map { |placement| length_of(placement) }
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

    it "reads back the voices in order" do
      expect(restored.voices.map { |voice| voice.placements.map(&:to_s) })
        .to eq flow.voices.map { |voice| voice.placements.map(&:to_s) }
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
      expect(restored.voices.first.placements.map { |placement| placement.syllables.transform_values(&:to_h) })
        .to eq flow.voices.first.placements.map { |placement| placement.syllables.transform_values(&:to_h) }
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
  end
end
