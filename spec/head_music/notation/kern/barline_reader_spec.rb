require "spec_helper"

describe HeadMusic::Notation::Kern::BarlineReader do
  def read(field)
    described_class.read(field, line_number: 8)
  end

  {"=1" => [1, false], "=12" => [12, false], "=" => [nil, false], "==" => [nil, true], "=1-" => [1, false]}.each do |field, expected|
    it "reads #{field}" do
      barline = read(field)
      expect([barline.number, barline.final]).to eq expected
    end
  end

  it "raises an unsupported-feature error for a bar number variant" do
    expect { read("=3b") }.to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /variants are not supported \(=3b\) \(line 8\)/)
  end
end
