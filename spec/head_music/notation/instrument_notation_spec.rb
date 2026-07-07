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

    it "is not equal to an object of another class" do
      expect(notation == "not a notation").to be(false)
      expect(notation).not_to eql(42)
    end
  end

  describe "#sounding_transposition" do
    it "reads the first staff's transposition when staves are present" do
      transposing = described_class.new(
        instrument: instrument,
        data: {"staves" => [{"clef" => "treble_clef", "sounding_transposition" => -14}]}
      )
      expect(transposing.sounding_transposition).to eq(-14)
    end

    it "is 0 when there are no staves" do
      empty = described_class.new(instrument: instrument, data: {})
      expect(empty.staves).to be_empty
      expect(empty.sounding_transposition).to eq(0)
    end
  end
end
