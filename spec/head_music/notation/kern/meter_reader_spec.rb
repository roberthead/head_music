require "spec_helper"

describe HeadMusic::Notation::Kern::MeterReader do
  it "reads a meter" do
    expect(described_class.meter("*M3/4")).to eq HeadMusic::Rudiment::Meter.get("3/4")
  end

  it "recognizes a meter but not a tempo or a mensuration sign" do
    expect(%w[*M6/8 *MM100 *met(c)].map { |field| described_class.meter?(field) }).to eq [true, false, false]
  end

  %w[*M3/5 *M0/4 *MX *M3/4+2/8].each do |field|
    it "raises an unsupported-feature error for #{field}" do
      expect { described_class.meter(field, line_number: 4) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Unsupported meter.*\(line 4\)/)
    end
  end

  it "writes a meter" do
    expect(described_class.meter_field(HeadMusic::Rudiment::Meter.get("6/8"))).to eq "*M6/8"
  end
end
