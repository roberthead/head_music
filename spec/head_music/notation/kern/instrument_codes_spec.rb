require "spec_helper"

describe HeadMusic::Notation::Kern::InstrumentCodes do
  {"soprn" => "soprano_voice", "alto" => "alto_voice", "tenor" => "tenor_voice", "bass" => "bass_voice"}.each do |code, name|
    it "maps *I#{code} to #{name}" do
      expect(described_class.instrument(code).name_key).to eq name.to_sym
    end
  end

  it "leaves an unknown code without an instrument" do
    expect(described_class.instrument("vox")).to be_nil
  end

  it "recognizes a code but not the class, group, abbreviation, or name forms" do
    expect(%w[*Isoprn *ICvox *IGsolo *I'S. *I"Soprano].map { |field| described_class.code?(field) })
      .to eq [true, false, false, false, false]
  end

  it "reads a code" do
    expect(described_class.code("*Itenor")).to eq "tenor"
  end

  it "reads a display name" do
    expect([described_class.name?('*I"Soprano'), described_class.name('*I"Soprano')]).to eq [true, "Soprano"]
  end

  it "recognizes the transposition interpretations" do
    expect(%w[*ITrd1c2 *Trd1c2 *Itenor].map { |field| described_class.transposition?(field) }).to eq [true, true, false]
  end

  it "writes an instrument's first code" do
    expect(described_class.code_field(HeadMusic::Instruments::Instrument.get("alto_voice"))).to eq "*Ialto"
  end

  it "writes no code for an instrument outside the table" do
    expect(described_class.code_field(HeadMusic::Instruments::Instrument.get("piano"))).to be_nil
  end

  it "writes a display name" do
    expect(described_class.name_field("Bass")).to eq '*I"Bass'
  end
end
