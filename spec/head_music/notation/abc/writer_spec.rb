require "spec_helper"

describe HeadMusic::Notation::ABC::Writer do
  describe "#to_s" do
    context "with a diatonic single-voice tune" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) { HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH) }

      let(:expected) do
        <<~ABC
          X:1
          T:Speed the Plough
          M:4/4
          L:1/8
          K:G
          |:GABc dedB|dedB dedB|c2ec B2dB|c2A2 A2BA|
          GABc dedB|dedB dedB|c2ec B2dB|A2F2 G4:|
        ABC
      end

      it "renders the full tune with its repeat" do
        expect(rendered).to eq expected
      end
    end

    context "with accidentals and same-bar natural cancellations" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) }

      let(:expected) do
        <<~ABC
          X:1
          T:Chromatic Air
          C:Trad.
          O:Nowhere in Particular
          M:4/4
          L:1/8
          K:Am
          A^GA=G ABc2|_BA^F=F E2A2|^c^de=d =c2B2|A2E2 A4|]
        ABC
      end

      it "renders the composer and origin header fields and minimal accidental marks" do
        expect(rendered).to eq expected
      end

      it "reproduces the original pitch spellings on re-parse" do
        reparsed = HeadMusic::Notation::ABC.parse(rendered)
        expect(reparsed.voices.first.pitches.map(&:to_s))
          .to eq flow.voices.first.pitches.map(&:to_s)
      end
    end

    context "with varied durations and rests" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Rest Study
        M:3/4
        L:1/8
        K:D
        A2z2FA|z3AB2|d6|z6|
      ABC

      let(:expected) do
        <<~ABC
          X:1
          T:Rest Study
          M:3/4
          L:1/8
          K:D
          A2 z2 FA|z3 AB2|d6|z6|]
        ABC
      end

      it "renders rests as z tokens with duration multipliers" do
        expect(rendered).to eq expected
      end
    end

    # The parser preserves an author's tied split on input (E3-E2 stays a
    # dotted quarter tied to a quarter), but the exporter is canonical: it
    # collapses any tied chain back to a single multiplier. The authored
    # split is intentionally not round-tripped through ABC export.
    context "with an authored tie collapsing to a single multiplier" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Tie Study
        M:6/8
        L:1/8
        K:C
        E3-E2 G|]
      ABC

      let(:expected) do
        <<~ABC
          X:1
          T:Tie Study
          M:6/8
          L:1/8
          K:C
          E5 G|]
        ABC
      end

      it "collapses the tied chain to one token, discarding the authored split" do
        expect(rendered).to eq expected
      end
    end

    # The parser fuses a tie across a bar line into one voice event, and ABC
    # has no other way to write a note that crosses the line, so the writer
    # splits it back at each bar and ties the pieces.
    context "with a voice event sounding across a bar line" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Ligature
        M:4/4
        L:1/4
        K:C
        z2 ^F2-|F4-|F2 E2|]
      ABC

      let(:expected) do
        <<~ABC
          X:1
          T:Ligature
          M:4/4
          L:1/8
          K:C
          z4 ^F4-|^F8-|^F4 E4|]
        ABC
      end

      it "writes one tied note per bar" do
        expect(rendered).to eq expected
      end

      it "round-trips to the same voice events" do
        reparsed = HeadMusic::Notation::ABC.parse(rendered).voices.first.voice_events
        expect(reparsed.map { |voice_event| [voice_event.position.code, voice_event.rhythmic_value.total_value] })
          .to eq flow.voices.first.voice_events.map { |voice_event| [voice_event.position.code, voice_event.rhythmic_value.total_value] }
      end
    end

    context "with a voice event crossing a bar line and ending on a later one" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) do
        HeadMusic::Content::Flow.new(name: "Breve", key_signature: "C major", meter: "4/4").tap do |flow|
          flow.add_voice.place("1:1", :"double whole", "C4")
        end
      end

      it "writes a full bar on each side of the line" do
        expect(rendered).to end_with "C8-|C8|]\n"
      end
    end

    context "with fractional durations shorter than the unit note length" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Sixteenth Study
        M:4/4
        L:1/8
        K:C
        C/D/E/F/ G3 A2 z|
      ABC

      let(:expected) do
        <<~ABC
          X:1
          T:Sixteenth Study
          M:4/4
          L:1/8
          K:C
          C1/2D1/2E1/2F1/2 G3 A2 z|]
        ABC
      end

      it "renders sixteenths with explicit fractional multipliers" do
        expect(rendered).to eq expected
      end

      it "round-trips" do
        expect_abc_round_trip(flow)
      end
    end

    context "with a custom reference number" do
      subject(:rendered) { described_class.new(flow, reference_number: 7).to_s }

      let(:flow) { HeadMusic::Content::Flow.new(name: "Ref Test") }

      it "writes the reference number into the X: field" do
        expect(rendered).to start_with "X:7\n"
      end
    end

    context "with a flow that has no voices" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) { HeadMusic::Content::Flow.new(name: "Nothing Yet") }

      let(:expected) do
        <<~ABC
          X:1
          T:Nothing Yet
          M:4/4
          L:1/8
          K:C
        ABC
      end

      it "renders the header with no body" do
        expect(rendered).to eq expected
      end

      it "re-parses without error" do
        expect { HeadMusic::Notation::ABC.parse(rendered) }.not_to raise_error
      end
    end

    context "with a flow that has one empty voice" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) do
        HeadMusic::Content::Flow.new(name: "Nothing Yet").tap(&:add_voice)
      end

      it "renders the header with no body" do
        expect(rendered.lines.last).to eq "K:C\n"
      end
    end

    context "with a flow of empty voices" do
      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          flow.add_voice
          flow.add_voice
        end
      end

      it "declares the voices and writes no bars" do
        expect(described_class.new(flow).to_s.lines.last(3)).to eq ["V:1\n", "V:2\n", "K:C\n"]
      end
    end

    context "with mid-piece meter changes" do
      let(:flow) do
        HeadMusic::Notation::ABC.parse("X:1\nT:Test\nM:4/4\nL:1/8\nK:C\nC8|D8|[M:3/4]E6|[M:C]F8|\n")
      end

      it "writes each as an inline field opening its bar, a change of symbol alone included" do
        expect(described_class.new(flow).to_s.lines.last).to eq "C8|D8|[M:3/4]E6|[M:C]F8|]\n"
      end
    end

    context "with a mid-piece key signature change" do
      let(:flow) do
        HeadMusic::Notation::ABC.parse("X:1\nT:Test\nM:4/4\nL:1/8\nK:C\nF8|[K:G]F8|=F8|\n")
      end

      it "writes it as an inline field and spells each bar in its key" do
        expect(described_class.new(flow).to_s.lines.last).to eq "F8|[K:G]F8|=F8|]\n"
      end
    end

    context "with a key change in a bar that opens a volta" do
      let(:flow) do
        HeadMusic::Notation::ABC.parse("X:1\nT:Test\nM:4/4\nL:1/8\nK:C\n|:C8|[1 D8:|[2 [K:G][M:3/4]G6|]\n")
      end

      it "writes the fields after the volta" do
        expect(described_class.new(flow).to_s.lines.last).to eq "|:C8|[1 D8:|[2 [M:3/4][K:G]G6|]\n"
      end
    end

    context "with a positional gap between voice events" do
      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          voice = flow.add_voice
          voice.place("1:1", :quarter, "C4")
          voice.place("2:1", :quarter, "D4")
        end
      end

      it "raises a RenderError telling the caller to insert rests" do
        expect { described_class.new(flow).to_s }.to raise_error(
          HeadMusic::Notation::ABC::RenderError, /insert explicit rests/
        )
      end
    end

    context "with a two-pitch chord voice event" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          flow.add_voice.place("1:1", :half, %w[C4 E4])
        end
      end

      it "emits a bracket group with the duration suffix outside the bracket" do
        expect(rendered.lines.last).to eq "[CE]4|]\n"
      end
    end

    context "with a three-pitch chord voice event" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          flow.add_voice.place("1:1", :half, %w[C4 E4 G4])
        end
      end

      it "emits all three pitch tokens inside one bracket group" do
        expect(rendered.lines.last).to eq "[CEG]4|]\n"
      end
    end

    context "with chord pitches placed in scrambled order" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          flow.add_voice.place("1:1", :half, %w[G4 C4 E4])
        end
      end

      it "emits the pitches sorted low to high" do
        expect(rendered.lines.last).to eq "[CEG]4|]\n"
      end
    end

    context "with a chord containing an accidental" do
      subject(:rendered) { described_class.new(flow).to_s }

      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          voice = flow.add_voice
          voice.place("1:1", :half, %w[C4 E4 G#4])
          voice.place("1:3", :quarter, "G#4")
          voice.place("1:4", :quarter, "G4")
        end
      end

      it "writes the accidental inside the bracket and carries the bar state forward" do
        expect(rendered.lines.last).to eq "[CE^G]4 G2 =G2|]\n"
      end
    end

    context "with a single unpitched sound voice event" do
      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          flow.add_voice.place("1:1", :quarter, HeadMusic::Rudiment::UnpitchedSound.get("snare drum"))
        end
      end

      it "raises a RenderError naming the sound and position" do
        expect { described_class.new(flow).to_s }.to raise_error(
          HeadMusic::Notation::ABC::RenderError,
          /cannot render unpitched sound "snare drum" at 1:1.*percussion rendering is not yet supported/
        )
      end
    end

    context "with a mixed pitched and unpitched voice event" do
      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          flow.add_voice.place("1:1", :quarter, ["C4", HeadMusic::Rudiment::UnpitchedSound.get("snare drum")])
        end
      end

      it "raises a RenderError naming the unpitched sound" do
        expect { described_class.new(flow).to_s }.to raise_error(
          HeadMusic::Notation::ABC::RenderError,
          /cannot render unpitched sound "snare drum" at 1:1/
        )
      end
    end

    context "with a first voice event that does not start its bar" do
      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          flow.add_voice.place("1:2", :quarter, "C4")
        end
      end

      it "raises a RenderError telling the caller to insert rests" do
        expect { described_class.new(flow).to_s }.to raise_error(
          HeadMusic::Notation::ABC::RenderError, /insert explicit rests/
        )
      end
    end
  end

  describe "authored beaming" do
    def body_line(rendered)
      rendered.lines.map(&:chomp).find { |line| line.end_with?("|]") }
    end

    it "suppresses spaces inside an authored beam group but keeps the authored space" do
      flow = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/8\nK:C\nCDEF GABc|]\n")
      rendered = HeadMusic::Notation::ABC.render(flow)
      expect(body_line(rendered)).to eq "CDEF GABc|]"
    end

    it "keeps one space per authored beam break" do
      flow = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/8\nK:C\nCD EF GA Bc|]\n")
      rendered = HeadMusic::Notation::ABC.render(flow)
      expect(body_line(rendered)).to eq "CD EF GA Bc|]"
    end

    context "with a programmatic (nil-flag) flow" do
      let(:programmatic) do
        HeadMusic::Content::Flow.new.tap do |comp|
          voice = comp.add_voice
          %w[1:1 1:1:480 1:2 1:2:480].zip(%w[C4 D4 E4 F4]).each do |position, pitch|
            voice.place(position, :eighth, pitch)
          end
        end
      end

      it "keeps every-note spacing" do
        expect(body_line(HeadMusic::Notation::ABC.render(programmatic))).to eq "C D E F|]"
      end
    end

    describe "idempotence" do
      let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/8\nK:C\nCDEF GABc|]\n") }
      let(:rendered) { HeadMusic::Notation::ABC.render(flow) }
      let(:reparsed) { HeadMusic::Notation::ABC.parse(rendered) }

      def flags(comp)
        comp.voices.first.voice_events.map(&:beam_break_before)
      end

      it "preserves the beam_break_before sequence on re-parse" do
        expect(flags(reparsed)).to eq flags(flow)
      end

      it "reaches a string fixpoint" do
        expect(HeadMusic::Notation::ABC.render(reparsed)).to eq rendered
      end
    end
  end

  describe "round trips" do
    it "round-trips Speed the Plough" do
      expect_abc_round_trip(HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH))
    end

    it "round-trips the accidental-heavy fixture" do
      expect_abc_round_trip(HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR))
    end

    context "with chord members at one letter and octave under two alterations" do
      def body_of(key, chord, after)
        flow = HeadMusic::Content::Flow.new(meter: "4/4", key_signature: key)
        flow.add_voice.place("1:1", :half, chord).voice.place("1:3", :half, after)
        described_class.new(flow).to_s.lines.last.chomp
      end

      it "writes the natural beside the sharp, and the bar follows the sharp" do
        expect(body_of("C major", %w[F4 F#4], "F4")).to eq "[=F^F]4 =F4|]"
      end

      it "writes the flat the key implies beside the natural" do
        expect(body_of("F major", %w[Bb4 B4], "Bb4")).to eq "[_B=B]4 _B4|]"
      end

      it "forces them on the chord's first part alone when it crosses a barline" do
        flow = HeadMusic::Content::Flow.new(meter: "4/4")
        flow.add_voice.place("1:1", :half, "C4").voice.place("1:3", :whole, %w[F4 F#4])
        expect(described_class.new(flow).to_s.lines.last.chomp).to eq "C4 [=F^F]4-|[F^F]4|]"
      end
    end

    context "with the chorale chord example" do
      let(:flow) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Chorale Fragment
        M:4/4
        L:1/4
        K:C
        [CEG]2 [DFA]2 | [EGC']4 |]
      ABC

      it "round-trips" do
        expect_abc_round_trip(flow)
      end
    end

    context "with chords containing accidentals" do
      let(:flow) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Accidental Chords
        M:4/4
        L:1/4
        K:C
        [^FA]2 F2 | [_BDF]2 B2 |]
      ABC

      it "round-trips" do
        expect_abc_round_trip(flow)
      end
    end

    context "with uniform per-note lengths" do
      let(:flow) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Uniform Inner Lengths
        M:4/4
        L:1/4
        K:C
        [C2E2G2] [D2F2A2] | [E2G2c2]2 |]
      ABC

      it "round-trips" do
        expect_abc_round_trip(flow)
      end

      it "normalizes inner lengths to the canonical outer-length form" do
        expect(HeadMusic::Notation::ABC.render(flow)).to include("[CEG]4 [DFA]4|[EGc]8")
      end
    end

    context "with a single-pitch bracket" do
      let(:flow) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Singleton
        M:4/4
        L:1/4
        K:C
        [C]4 |]
      ABC

      let(:rendered) { HeadMusic::Notation::ABC.render(flow) }
      let(:reparsed_voice_event) { HeadMusic::Notation::ABC.parse(rendered).voices.first.voice_events.first }

      it "normalizes to an unbracketed note" do
        expect(rendered.lines.last).to eq "C8|]\n"
      end

      it "re-parses as an equivalent single-note voice event" do
        expect(reparsed_voice_event.note?).to be true
        expect(reparsed_voice_event.chord?).to be false
        expect(reparsed_voice_event.pitch.to_s).to eq "C4"
      end
    end

    it "reaches a string fixpoint after one render" do
      [ABCFixtures::SPEED_THE_PLOUGH, ABCFixtures::CHROMATIC_AIR].each do |fixture|
        flow = HeadMusic::Notation::ABC.parse(fixture)
        rendered = HeadMusic::Notation::ABC.render(flow)
        expect(HeadMusic::Notation::ABC.render(HeadMusic::Notation::ABC.parse(rendered))).to eq rendered
      end
    end

    # ABC is an ASCII format and its consumers reject the unicode accidental signs
    # that Spelling#to_s produces. The existing fixtures all sit in keys with no
    # accidental in the tonic, so none of them exercises the K: rendering path that
    # could leak one.
    context "with a key signature whose tonic carries an accidental" do
      %w[Bb Eb Ab Db F# C# Bbm F#m].each do |abc_key|
        it "renders a #{abc_key} tune without unicode accidentals anywhere" do
          source = "X:1\nT:Test\nM:4/4\nL:1/8\nK:#{abc_key}\nCDEF GABc|\n"
          rendered = HeadMusic::Notation::ABC.render(HeadMusic::Notation::ABC.parse(source))
          expect(rendered).not_to match(/[♭♯♮𝄫𝄪]/)
        end
      end
    end
  end

  describe "markings" do
    def body_of(flow)
      described_class.new(flow).to_s.lines.drop(5).join
    end

    let(:flow) { HeadMusic::Content::Flow.new(name: "Marks", key_signature: "C major", meter: "4/4") }
    let(:voice) { flow.add_voice }

    it "writes every articulation, ornament, note dynamic, and level" do
      expect(body_of(MarkingFixtures.marked_melody)).to eq <<~ABC
        !p!.c2 .d2 .e2 .f2|!trill!g4 !sfz!a4|g8 & x4 !mf!x4|!tenuto!e2 !fp!f6|
        !f!!accent!!lowermordent!e4 !wedge!!uppermordent!d2 !marcato!!turn!c2|c4 !pp!z4|]
      ABC
    end

    it "writes decorations the parser reads back in a new spelling" do
      parsed = HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nK:C\nLC M!pralltriller!D !rfz!E !ff!z|\n")
      expect(body_of(parsed)).to eq "!accent!C2 !uppermordent!!lowermordent!D2 !rfz!E2 !ff!z2|]\n"
    end

    it "refuses a dynamic after the music ends" do
      voice.place("1:1", :whole, "C4")
      voice.place_dynamic("2:1", :f)
      expect { body_of(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError, /dynamic f at 2:1:000 falls after/)
    end

    it "writes a dynamic in the middle of a note on an overlay of invisible rests" do
      voice.place("1:1", :half, "C4")
      voice.place("1:3", :half, "D4")
      voice.place_dynamic("1:2", :f)
      expect(body_of(flow)).to eq "C4 D4 & x2 !f!x6|]\n"
    end

    it "writes every dynamic inside the bar's notes on one overlay" do
      voice.place("1:1", :whole, "C4")
      voice.place_dynamic("1:2", :p)
      voice.place_dynamic("1:3", :f)
      expect(body_of(flow)).to eq "C8 & x2 !p!x2 !f!x4|]\n"
    end

    it "fills the overlay to the end of a short final bar" do
      voice.place("1:1", :dotted_half, "C4")
      voice.place_dynamic("1:2", :p)
      expect(body_of(flow)).to eq "C6 & x2 !p!x4|]\n"
    end

    it "writes a dynamic under a rest on the overlay" do
      voice.place("1:1", :half, "C4")
      voice.place("1:3", :half)
      voice.place_dynamic("1:4", :p)
      expect(body_of(flow)).to eq "C4 z4 & x6 !p!x2|]\n"
    end

    it "writes a dynamic after the music on a trailing invisible rest" do
      %w[C4 D4 E4].each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch) }
      voice.place_dynamic("1:4", :f)
      expect(body_of(flow)).to eq "C2 D2 E2 !f!x2|]\n"
    end

    it "writes a dynamic after the music past a gap of invisible rest" do
      voice.place("1:1", :half, "C4")
      voice.place_dynamic("1:4", :f)
      expect(body_of(flow)).to eq "C4 x2 !f!x2|]\n"
    end

    it "writes the trailing invisible rests before the overlay" do
      voice.place("1:1", :half, "C4")
      voice.place_dynamic("1:2", :p)
      voice.place_dynamic("1:3", :f)
      expect(body_of(flow)).to eq "C4 !f!x4 & x2 !p!x6|]\n"
    end

    it "writes a dynamic at a bar line inside a tied note on the note's later part" do
      voice.place("1:3", :whole, "C4")
      voice.place("1:1", :half)
      voice.place_dynamic("2:1", :p)
      expect(body_of(flow)).to eq "z4 C4-|!p!C4|]\n"
    end

    it "writes a dynamic inside a tied note's later part on that bar's overlay" do
      voice.place("1:1", :half)
      voice.place("1:3", :whole, "C4")
      voice.place_dynamic("2:2", :p)
      expect(body_of(flow)).to eq "z4 C4-|C4 & x2 !p!x2|]\n"
    end

    it "refuses a dynamic no binary note value reaches, before writing anything" do
      voice.place("1:1", :whole, "C4")
      voice.place_dynamic(flow.position(1, 1, 1), :p)
      message = "cannot place the dynamic p at 1:1:001 in ABC output: no binary note value reaches it"
      expect { body_of(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError, message)
    end

    it "marks a note split across a bar line only where it starts" do
      voice.place("1:1", :half)
      voice.place("1:3", :whole, "C4").articulate(:staccato).embellish(:trill).note_dynamic = :sf
      voice.place_dynamic("1:3", :p)
      expect(body_of(flow)).to eq "z4 !p!.!trill!!sf!C4-|C4|]\n"
    end

    it "writes the part's dynamics on the voice, once where the voice has the same level" do
      voice.place("1:1", :half, "C4")
      voice.place("1:3", :half, "D4")
      [["1:1", :p], ["1:3", :f]].each { |position, level| voice.part.place_dynamic(position, level) }
      voice.place_dynamic("1:3", :f)
      expect(body_of(flow)).to eq "!p!C4 !f!D4|]\n"
    end

    it "refuses a part's and the voice's different levels at one position" do
      voice.place("1:1", :half, "C4")
      voice.place("1:3", :half, "D4")
      voice.part.place_dynamic("1:3", :f)
      voice.place_dynamic("1:3", :mf)
      expect { body_of(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError, /the f and the mf at 1:3:000 cannot both be written/)
    end
  end

  describe "hairpins" do
    def body_of(flow)
      described_class.new(flow).to_s.lines.drop(5).join
    end

    def four_quarters(hairpins = [])
      MarkingFixtures.four_quarters.tap do |flow|
        hairpins.each { |kind, from, to| flow.voices.first.add_span(kind, from: from, to: to) }
      end
    end

    let(:flow) { HeadMusic::Content::Flow.new(name: "Hairpins", key_signature: "C major", meter: "4/4") }
    let(:voice) { flow.add_voice }

    it "writes a crescendo and a diminuendo on the notes where they start and end" do
      expect(body_of(four_quarters([[:crescendo, "1:1", "1:3"], [:diminuendo, "1:4", "2:1"]])))
        .to eq "!<(!C2 D2 !<)!E2 !>(!F2|!>)!G8|]\n"
    end

    it "writes an end, then a level, then a start where they meet" do
      flow = four_quarters([[:diminuendo, "1:3", "2:1"], [:crescendo, "1:1", "1:3"]])
      flow.voices.first.place_dynamic("1:3", :mf)
      expect(body_of(flow)).to eq "!<(!C2 D2 !<)!!mf!!>(!E2 F2|!>)!G8|]\n"
    end

    it "writes a level inside a hairpin without cutting it" do
      flow = four_quarters([[:crescendo, "1:1", "2:1"]])
      flow.voices.first.place_dynamic("1:3", :mf)
      expect(body_of(flow)).to eq "!<(!C2 D2 !mf!E2 F2|!<)!G8|]\n"
    end

    it "writes an end on a tied note's later link before that link" do
      expect(body_of(HairpinFixtures.hairpin_ending_on_tied_note)).to eq "!<(!C2 D2 E2 F2-|!<)!F2 G2 A2 B2|]\n"
    end

    it "writes marks inside held notes on each bar's overlay" do
      expect(body_of(HairpinFixtures.hairpin_under_held_note)).to eq "C8 & x2 !<(!x6|D4 E4 & x2 !<)!x6|]\n"
    end

    it "writes an end on the final barline after a full bar on a spacer" do
      voice.place("1:1", :whole, "C4")
      voice.add_span(:crescendo, from: "1:1", to: "2:1")
      expect(body_of(flow)).to eq "!<(!C8 !<)!y|]\n"
    end

    it "fills a short final bar before an end on the final barline" do
      %w[C4 D4 E4].each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch) }
      voice.add_span(:diminuendo, from: "1:2", to: "2:1")
      expect(body_of(flow)).to eq "C2 !>(!D2 E2 x2 !>)!y|]\n"
    end

    it "writes an end at a short final bar's music end and a hairpin from there to the final barline" do
      expect(body_of(HairpinFixtures.hairpins_after_short_final_bar)).to eq "C8|!<(!C2 D2 E2 !<)!!>(!x2 !>)!y|]\n"
    end

    it "writes the final barline's spacer before the overlay" do
      voice.place("1:1", :whole, "C4")
      voice.add_span(:crescendo, from: "1:2", to: "2:1")
      expect(body_of(flow)).to eq "C8 !<)!y & x2 !<(!x6|]\n"
    end

    it "writes the part's hairpins on the voice, once where the voice has the same hairpin" do
      flow = four_quarters([[:crescendo, "1:1", "1:3"]])
      flow.parts.first.add_span(:crescendo, from: "1:1", to: "1:3")
      flow.parts.first.add_span(:diminuendo, from: "1:3", to: "2:1")
      expect(body_of(flow)).to eq "!<(!C2 D2 !<)!!>(!E2 F2|!>)!G8|]\n"
    end

    it "refuses a part's hairpin that overlaps the voice's, naming both" do
      flow = four_quarters([[:crescendo, "1:1", "1:3"]])
      flow.parts.first.add_span(:diminuendo, from: "1:2", to: "2:1")
      expect { body_of(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError,
        /an ABC voice holds one hairpin at a time, so the crescendo from 1:1:000 to 1:3:000 and the diminuendo from 1:2:000 to 2:1:000/)
    end

    it "refuses a hairpin mark no binary note value reaches, naming it" do
      voice.place("1:1", :whole, "C4")
      voice.add_span(:crescendo, from: flow.position(1, 1, 1), to: "2:1")
      expect { body_of(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError,
        "cannot place the crescendo start at 1:1:001 in ABC output: no binary note value reaches it")
    end
  end

  describe "slurs and phrases" do
    def last_line(flow)
      described_class.new(flow).to_s.lines.last.chomp
    end

    def four_quarters_with(*spans)
      MarkingFixtures.four_quarters.tap do |flow|
        spans.each { |kind, from, to| flow.voices.first.add_span(kind, from: from, to: to) }
      end
    end

    it "opens a slur before its first note and closes it after its last" do
      expect(last_line(four_quarters_with([:slur, "1:1", "1:3"]))).to eq "(C2 D2 E2) F2|G8|]"
    end

    it "opens a slur before the note's decorations, since .( is a dotted slur" do
      flow = four_quarters_with([:slur, "1:1", "1:2"])
      flow.voices.first.voice_events.first.articulate(:staccato)
      expect(last_line(flow)).to start_with "(.C2 D2)"
    end

    it "closes a slur after the last part of a note tied across a barline" do
      expect(last_line(MarkingFixtures.spanned_melody)).to include("c2-|c2)", "(f2-|f2 g2))")
    end

    it "nests slurs and writes a phrase as a slur drawn in from a rest to the last note" do
      expect(last_line(MarkingFixtures.spanned_melody))
        .to eq "((C2 D2 E2) F2|(G2 (A2 B2) c2-|c2) d2 e2 (f2-|f2 g2)) z4|]"
    end

    it "starts a slur that touches another on the note after" do
      expect(last_line(MarkingFixtures.touching_slurs)).to eq "(C2 D2 E2) (F2|G8)|]"
    end

    it "leaves out a slur that touching would leave one note long" do
      expect(last_line(four_quarters_with([:slur, "1:1", "1:3"], [:slur, "1:3", "1:4"]))).to eq "(C2 D2 E2) F2|G8|]"
    end

    it "leaves out a phrase that crosses a slur" do
      expect(last_line(MarkingFixtures.crossing_spans(:phrase, :slur))).to eq "C2 (D2 E2 F2)|G8|]"
    end

    it "leaves out a phrase that covers the same notes as a slur" do
      expect(last_line(four_quarters_with([:phrase, "1:1", "1:3"], [:slur, "1:1", "1:3"]))).to eq "(C2 D2 E2) F2|G8|]"
    end

    it "refuses slurs that cross" do
      expect { described_class.new(MarkingFixtures.crossing_spans).to_s }
        .to raise_error(HeadMusic::Notation::ABC::RenderError, "ABC cannot write slurs that cross, as from 1:1:000 and from 1:2:000")
    end
  end

  describe "tuplets" do
    def body_of(flow)
      described_class.new(flow).to_s.lines.last.chomp
    end

    {
      triplets: "(3C D E (3F G A (3B2 c2 d2|c8|]",
      sextuplet: "(6:4:6C1/2 D1/2 E1/2 F1/2 G1/2 A1/2 G6|C8|]",
      quintuplet: "(5:4:5C1/2 D1/2 E1/2 F1/2 G1/2 E6|C8|]",
      septuplet: "(7:4:7C1/2 D1/2 E1/2 F1/2 G1/2 A1/2 B1/2 c6|C8|]",
      mixed_value_tuplet: "(3:2:2C2 D (3:2:2z [EG]2 F4|E8|]",
      duplet_in_six_eight: "(2C E G3|c6|]",
      ungrouped_tuplet_run: "(3C D E (3F G A G4|C8|]",
      triplet_tied_out: "(3C D E-E2 F4|C8|]"
    }.each do |fixture, body|
      it "writes the #{fixture} fixture as #{body}" do
        expect(body_of(TupletFixtures.public_send(fixture))).to eq body
      end
    end

    it "writes a group starting on the later link of a tied note after the tie" do
      flow = TupletFixtures.flow("Tied In")
      triplet_eighths = TupletFixtures.run("3:2", :eighth, %w[D4 E4])
      voice = TupletFixtures.fill(flow.add_voice, [[TupletFixtures.value("quarter tied to triplet eighth"), "C4"], *triplet_eighths, [:half, "F4"]])
      voice.group_tuplet(from: "1:2", to: "1:3")
      expect(body_of(flow)).to eq "C2-(3C D E F4|]"
    end

    it "writes the marker before a slur and the decorations, and a level at a tuplet onset on its note" do
      flow = TupletFixtures.triplets
      voice = flow.voices.first.tap { |triplets| triplets.voice_events.first.articulate(:staccato) }
      voice.add_span(:slur, from: "1:1", to: "1:1:640")
      voice.place_dynamic("1:1:320", :p)
      expect(body_of(flow)).to start_with "(3(.C !p!D E)"
    end

    it "writes a value with a ratio but no group in a bracket of its own" do
      flow = TupletFixtures.flow("Lone")
      TupletFixtures.fill(flow.add_voice, [[TupletFixtures.value(:quarter, "3:2"), "C4"], [:half, "D4"]])
      expect(body_of(flow)).to start_with "(3:2:1C2 D4"
    end

    TupletFixtures.crossing_barline.each do |fixture|
      it "refuses the #{fixture} fixture, naming the group" do
        expect { described_class.new(TupletFixtures.public_send(fixture)).to_s }
          .to raise_error(HeadMusic::Notation::ABC::RenderError, /\AABC cannot write the \d:\d tuplet from 1:4:000 to 2:2:000 across the barline into bar 2\z/)
      end
    end
  end

  describe "grace notes" do
    def body_of(flow)
      described_class.new(flow).to_s.lines.last.chomp
    end

    let(:flow) { MarkingFixtures.four_quarters }
    let(:voice) { flow.voices.first }

    def note(index)
      voice.voice_events[index]
    end

    it "writes the grace_notes_before_downbeat fixture with its chord, articulation, slash, tie, and slur" do
      expect(body_of(TupletFixtures.grace_notes_before_downbeat)).to eq "C2 E2 {[Ac]1/2}G2 {.G1/2}F2|{/F}E8|({D1/2C1/2-}C8)|]"
    end

    it "starts a new group where slashed and unslashed grace notes meet" do
      note(1).add_grace_note("C4", :eighth, slashed: true).add_grace_note("E4", :eighth)
      expect(body_of(flow)).to start_with "C2 {/C}{E}D2"
    end

    it "writes the accidentals of a grace chord's members at one letter and octave" do
      note(1).add_grace_note(%w[D4 D#4], :eighth)
      expect(body_of(flow)).to start_with "C2 {[=D^D]}=D2"
    end

    it "writes the grace notes before their note, which then cancels an accidental they write" do
      note(1).add_grace_note("D#4", :eighth)
      expect(body_of(flow)).to start_with "C2 {^D}=D2"
    end

    it "writes a tuplet marker before the grace notes" do
      TupletFixtures.triplets.tap do |triplets|
        triplets.voices.first.voice_events.first.add_grace_note("B3", :eighth)
        expect(body_of(triplets)).to start_with "(3{B,}C D E"
      end
    end

    it "closes a slur from grace notes and one from an earlier note after their shared last note" do
      note(2).add_grace_note("C4", :eighth)
      voice.add_span(:slur, from: "1:1", to: "1:3")
      voice.add_span(:slur, from: "1:3", to: "1:3", from_grace: true)
      expect(body_of(flow)).to start_with "(C2 D2 ({C}E2))"
    end

    it "starts a slur from the main note of a slur from its grace notes on the note after, as touching slurs do" do
      note(2).add_grace_note("C4", :eighth)
      voice.add_span(:slur, from: "1:3", to: "1:3", from_grace: true)
      voice.add_span(:slur, from: "1:3", to: "2:1")
      expect(body_of(flow)).to eq "C2 D2 ({C}E2) (F2|G8)|]"
    end

    it "refuses a slur from grace notes that crosses one from an earlier note" do
      note(2).add_grace_note("C4", :eighth)
      voice.add_span(:slur, from: "1:1", to: "1:4")
      voice.add_span(:slur, from: "1:3", to: "2:1", from_grace: true)
      expect { body_of(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError, /slurs that cross/)
    end
  end

  describe "bar markings" do
    def body_of(flow)
      described_class.new(flow).to_s.lines.drop(5).join
    end

    def bar(number)
      flow.bars(number).last
    end

    let(:flow) do
      HeadMusic::Content::Flow.new(name: "Marks", key_signature: "C major", meter: "4/4").tap do |flow|
        voice = flow.add_voice
        %w[C4 D4 E4 F4].each_with_index { |pitch, index| voice.place("#{index + 1}:1", :whole, pitch) }
      end
    end

    it "writes double, final, and dotted barlines, and a dashed one as plain" do
      bar(1).barline = :double
      bar(2).barline = :final
      bar(3).barline = :dashed
      expect(body_of(flow)).to eq "C8||D8|]E8|F8|]\n"
    end

    it "writes a dotted barline" do
      bar(1).barline = :dotted
      expect(body_of(flow)).to eq "C8.|D8|E8|F8|]\n"
    end

    it "writes a styled last barline in place of the implied final one" do
      bar(4).barline = :double
      expect(body_of(flow)).to end_with "F8||\n"
    end

    it "writes repeats, a double repeat, and a repeat opening the tune" do
      [1, 2].each { |number| bar(number).starts_repeat = true }
      [1, 3, 4].each { |number| bar(number).ends_repeat_after_num_plays = 2 }
      expect(body_of(flow)).to eq "|:C8::D8|E8:|F8:|\n"
    end

    it "writes a repeat played three times as a plain closing repeat" do
      bar(2).ends_repeat_after_num_plays = 3
      expect(body_of(flow)).to eq "C8|D8:|E8|F8|]\n"
    end

    it "writes first and second endings" do
      bar(1).starts_repeat = true
      bar(2).plays_on_passes = [1, 2]
      bar(2).ends_repeat_after_num_plays = 3
      bar(3).plays_on_passes = [3]
      expect(body_of(flow)).to eq "|:C8|[1,2 D8:|[3 E8[|F8|]\n"
    end

    it "carries a volta across the bars it spans" do
      bar(2).plays_on_passes = [1]
      bar(3).plays_on_passes = [1]
      bar(3).ends_repeat_after_num_plays = 2
      bar(4).plays_on_passes = [2]
      expect(body_of(flow)).to eq "C8|[1 D8|E8:|[2 F8|]\n"
    end

    it "writes a part label after the bar line that opens its bar" do
      bar(1).rehearsal_mark = "A"
      bar(3).rehearsal_mark = "Verse"
      expect(body_of(flow)).to eq "[P:A]C8|D8|[P:Verse]E8|F8|]\n"
    end

    it "writes segno and coda signs before the bar line that opens their bar" do
      bar(1).segno = true
      bar(3).coda = true
      expect(body_of(flow)).to eq "!segno!C8|D8!coda!|E8|F8|]\n"
    end

    it "writes Fine, To Coda, and a jump before the bar line that closes their bar" do
      bar(1).fine = true
      bar(2).to_coda = true
      bar(4).jump = HeadMusic::Content::Jump.new(:da_capo, to: :fine)
      expect(body_of(flow)).to eq "C8!fine!|D8!dacoda!|E8|F8!D.C.alfine!|]\n"
    end

    {
      HeadMusic::Content::Jump.new(:da_capo) => "!D.C.!",
      HeadMusic::Content::Jump.new(:da_capo, to: :coda) => "!D.C.alcoda!",
      HeadMusic::Content::Jump.new(:dal_segno) => "!D.S.!",
      HeadMusic::Content::Jump.new(:dal_segno, to: :fine) => "!D.S.alfine!",
      HeadMusic::Content::Jump.new(:dal_segno, to: :coda) => "!D.S.alcoda!"
    }.each do |jump, decoration|
      it "writes #{jump} as #{decoration}" do
        bar(2).jump = jump
        expect(body_of(flow)).to eq "C8|D8#{decoration}|E8|F8|]\n"
      end
    end
  end

  describe "timeline expressions" do
    def tune(body, header = "")
      HeadMusic::Notation::ABC.parse("X:1\nT:Timeline\nM:4/4\nL:1/4\n#{header}K:C\n#{body}\n")
    end

    def body_of(flow)
      described_class.new(flow).to_s.lines.drop_while { |line| !line.start_with?("K:") }.drop(1).join
    end

    let(:flow) { tune("C D E F|G A B c|") }
    let(:slower) { HeadMusic::Rudiment::Tempo.new("quarter", 80) }

    {common_time: "M:C", cut_time: "M:C|"}.each do |meter, field|
      it "writes #{meter.to_s.tr("_", " ")} as #{field}" do
        flow = HeadMusic::Content::Flow.new(meter: HeadMusic::Rudiment::Meter.public_send(meter)).tap { |held| held.add_voice.place("1:1", :whole, "C4") }
        expect(described_class.new(flow).to_s.lines).to include("#{field}\n")
      end
    end

    it "writes a 4/4 with no symbol as M:4/4" do
      expect(described_class.new(flow).to_s.lines).to include("M:4/4\n")
    end

    it "writes the opening tempo as Q: before K:" do
      lines = described_class.new(tune("C D E F|", %(Q:"Allegro" 1/4=132\n))).to_s.lines
      expect(lines.each_cons(2).to_a).to include([%(Q:"Allegro" 1/4=132\n), "K:C\n"])
    end

    it "writes no Q: for a quarter at 120" do
      expect(described_class.new(flow).to_s).not_to include("Q:")
    end

    it "writes a tempo change at its downbeat" do
      flow.change_tempo(2, slower)
      expect(body_of(flow)).to eq "C2 D2 E2 F2|[Q:1/4=80]G2 A2 B2 c2|]\n"
    end

    it "writes a ramp's text at its start and its target at its end" do
      flow.add_tempo_ramp(from: "1:3", to: "2:3", to_tempo: slower, text: "rall.")
      expect(body_of(flow)).to eq %(C2 D2 "^rall."E2 F2|G2 A2 [Q:1/4=80]B2 c2|]\n)
    end

    it "writes an \"a tempo\" as an annotation" do
      flow.add_tempo_ramp(from: "1:3", to: "2:1", text: "rit.")
      flow.add_a_tempo("2:1")
      expect(body_of(flow)).to eq %(C2 D2 "^rit."E2 F2|"^a tempo"G2 A2 B2 c2|]\n)
    end

    it "writes a ramp's target on the final barline" do
      flow.add_tempo_ramp(from: "2:1", to: "3:1", to_tempo: slower, text: "rit.")
      expect(body_of(flow)).to eq %(C2 D2 E2 F2|"^rit."G2 A2 B2 c2 [Q:1/4=80]y|]\n)
    end

    it "writes a ramp starting inside a note in an overlay" do
      flow = tune("C4|D4|").tap { |held| held.add_tempo_ramp(from: "1:3", to: "3:1", text: "rit.") }
      expect(body_of(flow)).to eq %(C8 & x4 "^rit."x4|D8|]\n)
    end

    it "writes a fermata on the event where it begins, rests included" do
      flow = tune("C D z F|").tap { |held| held.add_fermata("1:2", :quarter).then { held.add_fermata("1:3", :quarter) } }
      expect(body_of(flow)).to eq "C2 !fermata!D2 !fermata!z2 F2|]\n"
    end

    it "writes a fermata beginning in a tied note's later bar on that bar's part" do
      flow = tune("C2 D2-|D2 E2|").tap { |held| held.add_fermata("2:1", :half) }
      expect(body_of(flow)).to eq "C4 D4-|!fermata!D4 E4|]\n"
    end

    it "writes a fermata on a tied note's later link within a bar on that link" do
      flow = tune("C D- HD F|")
      expect(body_of(flow)).to eq "C2 D2-!fermata!D2 F2|]\n"
    end

    it "keeps a fermata within an untied note on the note" do
      flow = tune("C D2 F|").tap { |held| held.add_fermata("1:3", :quarter) }
      expect(body_of(flow)).to eq "C2 !fermata!D4 F2|]\n"
    end

    {
      "a fractional tempo" => [->(flow) { flow.change_tempo(2, HeadMusic::Rudiment::Tempo.new("quarter", 92.5)) }, /fractional tempo of 92.5/],
      "tempo text holding a double quote" => [->(flow) { flow.change_tempo(2, HeadMusic::Rudiment::Tempo.new("quarter", 92, text: 'So "fast"')) }, /double quote/],
      "an \"a tempo\" holding a double quote" => [->(flow) { flow.add_a_tempo("2:1", text: '"a tempo"') }, /double quote/],
      "a ramp whose text is no ramp word" => [->(flow) { flow.add_tempo_ramp(from: "1:1", to: "2:1", to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 80), text: "allarg.") }, /tempo ramp from 1:1:000 to 2:1:000.*reads back/],
      "a ramp's target where no note starts" => [->(flow) { flow.add_tempo_ramp(from: "1:1", to: "1:3:240", to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 80), text: "rit.") }, /tempo ramp end at 1:3:240 .*where no note starts/]
    }.each do |description, (change, message)|
      it "raises a RenderError for #{description}" do
        change.call(flow)
        expect { described_class.new(flow).to_s }.to raise_error(HeadMusic::Notation::ABC::RenderError, message)
      end
    end
  end
end
