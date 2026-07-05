require "spec_helper"

describe HeadMusic::Notation::NotationStyle do
  describe ".get" do
    it "returns a NotationStyle" do
      expect(described_class.get(:british_brass_band)).to be_a(described_class)
    end

    it "memoizes styles (same object for the same key)" do
      style = described_class.get(:default)
      expect(described_class.get(:default)).to be(style)
    end

    it "accepts a string or symbol interchangeably" do
      expect(described_class.get("british_brass_band")).to be(described_class.get(:british_brass_band))
    end

    it "returns the argument when already a NotationStyle" do
      style = described_class.get(:default)
      expect(described_class.get(style)).to be(style)
    end

    it "raises for an unknown style" do
      expect { described_class.get(:nonexistent_style) }.to raise_error(KeyError)
    end
  end

  describe ".default" do
    it "returns the default style" do
      expect(described_class.default.key).to eq(:default)
    end
  end

  describe ".all" do
    it "returns every defined style" do
      expect(described_class.all.map(&:key)).to contain_exactly(
        :default, :british_brass_band, :german, :italian, :concert_pitch
      )
    end
  end

  describe "#notation_for" do
    subject(:style) { described_class.get(style_key) }

    def clefs_for(style_key, instrument)
      described_class.get(style_key).notation_for(instrument).clefs.map(&:to_s)
    end

    def transposition_for(style_key, instrument)
      described_class.get(style_key).notation_for(instrument).sounding_transposition
    end

    context "with the default style" do
      let(:style_key) { :default }

      it "resolves a single-staff instrument" do
        notation = style.notation_for("euphonium")
        expect(notation.clefs.map(&:to_s)).to eq(["bass clef"])
        expect(notation.sounding_transposition).to eq(0)
        expect(notation).to be_single_staff
      end

      it "resolves a grand-staff instrument" do
        notation = style.notation_for("piano")
        expect(notation.staves.length).to eq(2)
        expect(notation.clefs.map(&:to_s)).to eq(["treble clef", "bass clef"])
        expect(notation).to be_multiple_staves
      end

      it "preserves per-staff name_keys for grand-staff instruments" do
        names = style.notation_for("piano").staves.map(&:name_key)
        expect(names).to eq(%w[right_hand left_hand])
      end

      it "resolves a three-staff instrument" do
        expect(style.notation_for("organ").staves.length).to eq(3)
      end

      it "returns nil for an unknown instrument" do
        expect(style.notation_for("nonexistent_instrument")).to be_nil
      end

      it "accepts an Instrument object as well as a key" do
        instrument = HeadMusic::Instruments::Instrument.get("euphonium")
        expect(style.notation_for(instrument)).to eq(style.notation_for("euphonium"))
      end
    end

    context "with the british_brass_band overlay" do
      let(:style_key) { :british_brass_band }

      it "overrides the instruments it lists" do
        expect(clefs_for(:british_brass_band, "euphonium")).to eq(["treble clef"])
        expect(transposition_for(:british_brass_band, "euphonium")).to eq(-14)
        expect(transposition_for(:british_brass_band, "tuba")).to eq(-26)
        expect(transposition_for(:british_brass_band, "baritone_horn")).to eq(-14)
      end

      it "falls back to default for instruments it does not list" do
        expect(clefs_for(:british_brass_band, "trombone")).to eq(clefs_for(:default, "trombone"))
        expect(clefs_for(:british_brass_band, "piano")).to eq(["treble clef", "bass clef"])
      end
    end

    context "with the german and italian overlays" do
      it "resolves the bass clarinet per tradition" do
        expect(transposition_for(:german, "bass_clarinet")).to eq(-2)
        expect(transposition_for(:italian, "bass_clarinet")).to eq(-9)
      end
    end

    context "with the concert_pitch overlay" do
      let(:style_key) { :concert_pitch }

      it "zeroes an interval-transposer's transposition, keeping its clef" do
        expect(clefs_for(:concert_pitch, "french_horn")).to eq(["treble clef"])
        expect(transposition_for(:concert_pitch, "french_horn")).to eq(0)
        expect(transposition_for(:concert_pitch, "clarinet")).to eq(0)
      end

      it "leaves octave-transposers alone (falls back to default, keeping the octave)" do
        expect(transposition_for(:concert_pitch, "piccolo_flute"))
          .to eq(transposition_for(:default, "piccolo_flute"))
      end
    end

    context "with recorded alternatives" do
      it "records the french horn low-register bass-clef alternative" do
        alternatives = described_class.default.notation_for("french_horn").alternatives
        expect(alternatives.map { |staff| staff.clef.to_s }).to include("bass clef")
        expect(alternatives.map { |staff| staff.attributes["category"] }).to include("range")
      end

      it "records the tenor voice clef alternatives" do
        alternatives = described_class.default.notation_for("tenor_voice").alternatives
        expect(alternatives.map { |staff| staff.attributes["clef"] })
          .to contain_exactly("bass_clef", "tenor_clef", "treble_clef")
      end

      it "does not record alternatives for instruments without any" do
        expect(described_class.default.notation_for("violin").alternatives).to be_empty
      end
    end
  end
end
