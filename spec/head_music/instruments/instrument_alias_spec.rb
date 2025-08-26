require "spec_helper"

describe "HeadMusic::Instruments::InstrumentType" do
  describe "get" do
    context "when using an alias name" do
      let(:piccolo_by_alias) { HeadMusic::Instruments::InstrumentType.get("piccolo") }
      let(:piccolo_by_name) { HeadMusic::Instruments::InstrumentType.get("piccolo_flute") }

      it "returns the instrument when using 'piccolo' (alias for piccolo_flute)" do
        expect(piccolo_by_alias.name).to eq("piccolo flute")
        expect(piccolo_by_alias.name_key).to eq(:piccolo_flute)
      end

      it "returns the same instrument for both the main name and alias" do
        expect(piccolo_by_alias.name).to eq(piccolo_by_name.name)
        expect(piccolo_by_alias.name_key).to eq(piccolo_by_name.name_key)
      end

      it "returns piano for 'pianoforte' alias" do
        instrument = HeadMusic::Instruments::InstrumentType.get("pianoforte")
        expect(instrument.name).to eq("piano")
        expect(instrument.name_key).to eq(:piano)
      end

      it "returns cor anglais for 'English horn' alias" do
        instrument = HeadMusic::Instruments::InstrumentType.get("English horn")
        expect(instrument).not_to be_nil
        expect(instrument.name_key).to eq(:cor_anglais)
      end
    end
  end
end
