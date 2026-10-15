require "spec_helper"

describe HeadMusic::Notation::MEI::Durations do
  def value(name)
    HeadMusic::Rudiment::RhythmicValue.get(name)
  end

  it "writes every unit the gem knows" do
    names = %w[maxima longa double_whole whole half quarter eighth sixteenth thirty_second sixty_fourth]
    expect(names.map { |name| described_class.dur(value(name)) }).to eq %w[maxima long breve 1 2 4 8 16 32 64]
  end

  it "writes the dots where there are any" do
    expect(described_class.attributes(value("double dotted quarter"))).to eq("dur" => "4", "dots" => 2)
  end

  it "leaves out dots where there are none" do
    expect(described_class.attributes(value(:quarter))).to eq("dur" => "4", "dots" => nil)
  end

  it "raises for a unit MEI cannot write" do
    unknown = instance_double(HeadMusic::Rudiment::RhythmicValue, unit_name: "five hundred twelfth")
    expect { described_class.dur(unknown) }.to raise_error(HeadMusic::Notation::MEI::RenderError, /five hundred twelfth/)
  end
end
