require "spec_helper"

describe HeadMusic::Notation::Kern::InterpretationReader do
  def kind(field)
    described_class.read(field, line_number: 3)&.kind
  end

  {
    "*MM100" => :tempo, "*M3/4" => :meter, "*k[f#]" => :signature, "*G:" => :designation,
    "*clefG2" => :clef, '*I"Alto' => :name, "*Ialto" => :code, "*part2" => :part, "*staff1" => :staff
  }.each do |field, expected|
    it "reads #{field} as #{expected}" do
      expect(kind(field)).to eq expected
    end
  end

  %w[* *>A *>[A,A,B] *met(c) *ICvox *stem *^ *-].each do |field|
    it "ignores #{field}" do
      expect(kind(field)).to be_nil
    end
  end

  it "reads the number of a part tag" do
    expect(described_class.read("*part3").value).to eq 3
  end

  it "keeps the field it read" do
    expect(described_class.read("*staff2").field).to eq "*staff2"
  end

  it "raises an unsupported-feature error for a cross-staff tag" do
    expect { kind("*staff1/2") }
      .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Cross-staff spines.*\(line 3\)/)
  end

  it "raises an unsupported-feature error for a transposition" do
    expect { kind("*Trd1c2") }.to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Transposed spines/)
  end
end
