require "spec_helper"

describe HeadMusic::Notation::InstrumentNotation do
  let(:instrument) { HeadMusic::Instruments::Instrument.get("euphonium") }
  let(:data) { {"staves" => [{"clef" => "bass_clef", "sounding_transposition" => 0}]} }
  let(:notation) { described_class.new(instrument: instrument, data: data) }
  let(:identical) { described_class.new(instrument: instrument, data: data) }

  describe "value equality" do
    it "treats distinct instances with the same instrument and staves as equal" do
      expect(notation).to eq(identical)
      expect(notation).to eql(identical)
    end

    it "hashes equal instances alike (so uniq and Hash keys collapse them)" do
      expect(notation.hash).to eq(identical.hash)
      expect([notation, identical].uniq).to eq([notation])
    end

    it "differs when the staves differ" do
      other = described_class.new(instrument: instrument, data: {"staves" => [{"clef" => "treble_clef"}]})
      expect(notation).not_to eq(other)
    end

    it "differs when the instrument differs" do
      other = described_class.new(instrument: HeadMusic::Instruments::Instrument.get("violin"), data: data)
      expect(notation).not_to eq(other)
    end
  end
end
