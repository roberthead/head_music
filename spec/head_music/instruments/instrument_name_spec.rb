require "spec_helper"

describe HeadMusic::Instruments::InstrumentName do
  describe "#to_s" do
    it "prefers an explicit translation of the instrument's own key" do
      name = described_class.new(name_key: :violin, parent_key: nil, pitch_designation: nil)
      expect(name.to_s).to eq I18n.translate(:violin, scope: %i[head_music instruments], locale: "en")
    end

    it "composes a child instrument name from the parent and pitch" do
      name = described_class.new(name_key: :made_up_horn, parent_key: :made_up_parent, pitch_designation: "Bb")
      expect(name.to_s).to eq "made up parent in B♭"
    end

    it "renders a sharp pitch designation with a sharp sign" do
      name = described_class.new(name_key: :made_up_horn, parent_key: :made_up_parent, pitch_designation: "F#")
      expect(name.to_s).to eq "made up parent in F♯"
    end

    it "infers a plain name from the key when nothing else applies" do
      name = described_class.new(name_key: :slide_whistle_thing, parent_key: nil, pitch_designation: nil)
      expect(name.to_s).to eq "slide whistle thing"
    end
  end

  describe ".translate" do
    it "returns the localized instrument name for a known key" do
      expect(described_class.translate(:violin)).to eq I18n.translate(:violin, scope: %i[head_music instruments], locale: "en")
    end

    it "returns the given default for an unknown key" do
      expect(described_class.translate(:no_such_instrument, default: "fallback")).to eq "fallback"
    end
  end
end
