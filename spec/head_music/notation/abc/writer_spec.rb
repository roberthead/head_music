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
          G A B c d e d B|d e d B d e d B|c2 e c B2 d B|c2 A2 A2 B A|
          G A B c d e d B|d e d B d e d B|c2 e c B2 d B|A2 F2 G4|]
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
          A ^G A =G A B c2|_B A ^F =F E2 A2|^c ^d e =d =c2 B2|A2 E2 A4|]
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
          A2 z2 F A|z3 A B2|d6|z6|]
        ABC
      end

      it "renders rests as z tokens with duration multipliers" do
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
          C1/2 D1/2 E1/2 F1/2 G3 A2 z|]
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

    context "with a chord placement" do
      let(:composition) do
        HeadMusic::Content::Composition.new.tap do |composition|
          composition.add_voice.place("1:1", :half, %w[C4 E4 G4])
        end
      end

      it "raises a RenderError explaining that chords are not yet supported" do
        expect { described_class.new(composition).to_s }.to raise_error(
          HeadMusic::Notation::ABC::RenderError, /chords are not yet supported by the ABC writer/
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

  describe "round trips" do
    it "round-trips Speed the Plough" do
      expect_abc_round_trip(HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH))
    end

    it "round-trips the accidental-heavy fixture" do
      expect_abc_round_trip(HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR))
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
