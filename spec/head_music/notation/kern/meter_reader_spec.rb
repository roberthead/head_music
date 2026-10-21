require "spec_helper"

describe HeadMusic::Notation::Kern::MeterReader do
  it "reads a meter" do
    expect(described_class.meter("*M3/4")).to eq HeadMusic::Rudiment::Meter.get("3/4")
  end

  it "recognizes a meter but not a tempo or a mensuration sign" do
    expect(%w[*M6/8 *MM100 *met(c) *MX].map { |field| described_class.meter?(field) }).to eq [true, false, false, false]
  end

  %w[*M3/5 *M0/4 *MX *M3/4+2/8].each do |field|
    it "raises an unsupported-feature error for #{field}" do
      expect { described_class.meter(field, line_number: 4) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Unsupported meter.*\(line 4\)/)
    end
  end

  it "recognizes the common- and cut-time signs but no other mensuration sign" do
    expect(%w[*met(c) *met(c|) *met(C) *met(O) *M4/4].map { |field| described_class.symbol?(field) }).to eq [true, true, false, false, false]
  end

  it "joins a sign to the meter it draws" do
    meter = described_class.with_symbol(described_class.meter("*M2/2"), described_class.symbol("*met(c|)"))
    expect(meter.symbol).to eq :cut
  end

  it "leaves out a sign that draws another meter" do
    expect(described_class.with_symbol(described_class.meter("*M3/4"), :common).symbol).to be_nil
  end

  it "writes the sign of a meter with one, and nothing for one without" do
    expect([HeadMusic::Rudiment::Meter.common_time, HeadMusic::Rudiment::Meter.get("4/4")].map { |meter| described_class.symbol_field(meter) })
      .to eq ["*met(c)", nil]
  end

  it "writes a meter" do
    expect(described_class.meter_field(HeadMusic::Rudiment::Meter.get("6/8"))).to eq "*M6/8"
  end
end
