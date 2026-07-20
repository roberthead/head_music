require "spec_helper"

describe HeadMusic::Notation::ABC::Writer do
  describe "#to_s" do
    context "with a diatonic single-voice tune" do
      subject(:rendered) { described_class.new(composition).to_s }

      let(:composition) { HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH) }

      let(:expected) do
        <<~ABC
          X:1
          T:Speed the Plough
          M:4/4
          L:1/8
          K:G
          GABc dedB|dedB dedB|c2ec B2dB|c2A2 A2BA|
          GABc dedB|dedB dedB|c2ec B2dB|A2F2 G4|]
        ABC
      end

      it "renders the full tune, degrading repeat barlines to plain bar lines" do
        expect(rendered).to eq expected
      end
    end

    context "with accidentals and same-bar natural cancellations" do
      subject(:rendered) { described_class.new(composition).to_s }

      let(:composition) { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) }

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
          .to eq composition.voices.first.pitches.map(&:to_s)
      end
    end

    context "with varied durations and rests" do
      subject(:rendered) { described_class.new(composition).to_s }

      let(:composition) { HeadMusic::Notation::ABC.parse(<<~ABC) }
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
      subject(:rendered) { described_class.new(composition).to_s }

      let(:composition) { HeadMusic::Notation::ABC.parse(<<~ABC) }
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

    context "with fractional durations shorter than the unit note length" do
      subject(:rendered) { described_class.new(composition).to_s }

      let(:composition) { HeadMusic::Notation::ABC.parse(<<~ABC) }
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
        expect_abc_round_trip(composition)
      end
    end

    context "with a custom reference number" do
      subject(:rendered) { described_class.new(composition, reference_number: 7).to_s }

      let(:composition) { HeadMusic::Content::Composition.new(name: "Ref Test") }

      it "writes the reference number into the X: field" do
        expect(rendered).to start_with "X:7\n"
      end
    end

    context "with a composition that has no voices" do
      subject(:rendered) { described_class.new(composition).to_s }

      let(:composition) { HeadMusic::Content::Composition.new(name: "Nothing Yet") }

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

    context "with a composition that has one empty voice" do
      subject(:rendered) { described_class.new(composition).to_s }

      let(:composition) do
        HeadMusic::Content::Composition.new(name: "Nothing Yet").tap(&:add_voice)
      end

      it "renders the header with no body" do
        expect(rendered.lines.last).to eq "K:C\n"
      end
    end

    context "with a multi-voice composition" do
      let(:composition) do
        HeadMusic::Content::Composition.new.tap do |composition|
          composition.add_voice
          composition.add_voice
        end
      end

      it "raises a RenderError" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::ABC::RenderError, /multi-voice/
        )
      end
    end

    context "with a mid-piece meter change" do
      let(:composition) do
        HeadMusic::Notation::ABC.parse("X:1\nT:Test\nM:4/4\nL:1/8\nK:C\nC8|D8|E8|F8|\n").tap do |composition|
          composition.change_meter(3, "3/4")
        end
      end

      it "raises a RenderError" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::ABC::RenderError, /meter change at bar 3/
        )
      end
    end

    context "with a mid-piece key signature change" do
      let(:composition) do
        HeadMusic::Notation::ABC.parse("X:1\nT:Test\nM:4/4\nL:1/8\nK:C\nC8|D8|E8|F8|\n").tap do |composition|
          composition.change_key_signature(2, "G major")
        end
      end

      it "raises a RenderError" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::ABC::RenderError, /key signature change at bar 2/
        )
      end
    end

    context "with a positional gap between placements" do
      let(:composition) do
        HeadMusic::Content::Composition.new.tap do |composition|
          voice = composition.add_voice
          voice.place("1:1", :quarter, "C4")
          voice.place("2:1", :quarter, "D4")
        end
      end

      it "raises a RenderError telling the caller to insert rests" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::ABC::RenderError, /insert explicit rests/
        )
      end
    end

    context "with a two-pitch chord placement" do
      subject(:rendered) { described_class.new(composition).to_s }

      let(:composition) do
        HeadMusic::Content::Composition.new.tap do |composition|
          composition.add_voice.place("1:1", :half, %w[C4 E4])
        end
      end

      it "emits a bracket group with the duration suffix outside the bracket" do
        expect(rendered.lines.last).to eq "[CE]4|]\n"
      end
    end

    context "with a three-pitch chord placement" do
      subject(:rendered) { described_class.new(composition).to_s }

      let(:composition) do
        HeadMusic::Content::Composition.new.tap do |composition|
          composition.add_voice.place("1:1", :half, %w[C4 E4 G4])
        end
      end

      it "emits all three pitch tokens inside one bracket group" do
        expect(rendered.lines.last).to eq "[CEG]4|]\n"
      end
    end

    context "with chord pitches placed in scrambled order" do
      subject(:rendered) { described_class.new(composition).to_s }

      let(:composition) do
        HeadMusic::Content::Composition.new.tap do |composition|
          composition.add_voice.place("1:1", :half, %w[G4 C4 E4])
        end
      end

      it "emits the pitches sorted low to high" do
        expect(rendered.lines.last).to eq "[CEG]4|]\n"
      end
    end

    context "with a chord containing an accidental" do
      subject(:rendered) { described_class.new(composition).to_s }

      let(:composition) do
        HeadMusic::Content::Composition.new.tap do |composition|
          voice = composition.add_voice
          voice.place("1:1", :half, %w[C4 E4 G#4])
          voice.place("1:3", :quarter, "G#4")
          voice.place("1:4", :quarter, "G4")
        end
      end

      it "writes the accidental inside the bracket and carries the bar state forward" do
        expect(rendered.lines.last).to eq "[CE^G]4 G2 =G2|]\n"
      end
    end

    context "with a single unpitched sound placement" do
      let(:composition) do
        HeadMusic::Content::Composition.new.tap do |composition|
          composition.add_voice.place("1:1", :quarter, HeadMusic::Rudiment::UnpitchedSound.get("snare drum"))
        end
      end

      it "raises a RenderError naming the sound and position" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::ABC::RenderError,
          /cannot render unpitched sound "snare drum" at 1:1.*percussion rendering is not yet supported/
        )
      end
    end

    context "with a mixed pitched and unpitched placement" do
      let(:composition) do
        HeadMusic::Content::Composition.new.tap do |composition|
          composition.add_voice.place("1:1", :quarter, ["C4", HeadMusic::Rudiment::UnpitchedSound.get("snare drum")])
        end
      end

      it "raises a RenderError naming the unpitched sound" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::ABC::RenderError,
          /cannot render unpitched sound "snare drum" at 1:1/
        )
      end
    end

    context "with a first placement that does not start its bar" do
      let(:composition) do
        HeadMusic::Content::Composition.new.tap do |composition|
          composition.add_voice.place("1:2", :quarter, "C4")
        end
      end

      it "raises a RenderError telling the caller to insert rests" do
        expect { described_class.new(composition).to_s }.to raise_error(
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
      composition = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/8\nK:C\nCDEF GABc|]\n")
      rendered = HeadMusic::Notation::ABC.render(composition)
      expect(body_line(rendered)).to eq "CDEF GABc|]"
    end

    it "keeps one space per authored beam break" do
      composition = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/8\nK:C\nCD EF GA Bc|]\n")
      rendered = HeadMusic::Notation::ABC.render(composition)
      expect(body_line(rendered)).to eq "CD EF GA Bc|]"
    end

    context "with a programmatic (nil-flag) composition" do
      let(:programmatic) do
        HeadMusic::Content::Composition.new.tap do |comp|
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
      let(:composition) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/8\nK:C\nCDEF GABc|]\n") }
      let(:rendered) { HeadMusic::Notation::ABC.render(composition) }
      let(:reparsed) { HeadMusic::Notation::ABC.parse(rendered) }

      def flags(comp)
        comp.voices.first.placements.map(&:beam_break_before)
      end

      it "preserves the beam_break_before sequence on re-parse" do
        expect(flags(reparsed)).to eq flags(composition)
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

    context "with the chorale chord example" do
      let(:composition) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Chorale Fragment
        M:4/4
        L:1/4
        K:C
        [CEG]2 [DFA]2 | [EGC']4 |]
      ABC

      it "round-trips" do
        expect_abc_round_trip(composition)
      end
    end

    context "with chords containing accidentals" do
      let(:composition) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Accidental Chords
        M:4/4
        L:1/4
        K:C
        [^FA]2 F2 | [_BDF]2 B2 |]
      ABC

      it "round-trips" do
        expect_abc_round_trip(composition)
      end
    end

    context "with uniform per-note lengths" do
      let(:composition) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Uniform Inner Lengths
        M:4/4
        L:1/4
        K:C
        [C2E2G2] [D2F2A2] | [E2G2c2]2 |]
      ABC

      it "round-trips" do
        expect_abc_round_trip(composition)
      end

      it "normalizes inner lengths to the canonical outer-length form" do
        expect(HeadMusic::Notation::ABC.render(composition)).to include("[CEG]4 [DFA]4|[EGc]8")
      end
    end

    context "with a single-pitch bracket" do
      let(:composition) { HeadMusic::Notation::ABC.parse(<<~ABC) }
        X:1
        T:Singleton
        M:4/4
        L:1/4
        K:C
        [C]4 |]
      ABC

      let(:rendered) { HeadMusic::Notation::ABC.render(composition) }
      let(:reparsed_placement) { HeadMusic::Notation::ABC.parse(rendered).voices.first.placements.first }

      it "normalizes to an unbracketed note" do
        expect(rendered.lines.last).to eq "C8|]\n"
      end

      it "re-parses as an equivalent single-note placement" do
        expect(reparsed_placement.note?).to be true
        expect(reparsed_placement.chord?).to be false
        expect(reparsed_placement.pitch.to_s).to eq "C4"
      end
    end

    it "reaches a string fixpoint after one render" do
      [ABCFixtures::SPEED_THE_PLOUGH, ABCFixtures::CHROMATIC_AIR].each do |fixture|
        composition = HeadMusic::Notation::ABC.parse(fixture)
        rendered = HeadMusic::Notation::ABC.render(composition)
        expect(HeadMusic::Notation::ABC.render(HeadMusic::Notation::ABC.parse(rendered))).to eq rendered
      end
    end
  end
end
