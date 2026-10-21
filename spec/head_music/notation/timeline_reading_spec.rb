require "spec_helper"

describe HeadMusic::Notation::TimelineReading do
  subject(:flow) { reading_class.new(bar_map).flow(identity) }

  let(:meter) { HeadMusic::Rudiment::Meter.get("4/4") }
  let(:bar_map) { instance_double(HeadMusic::Notation::BarMap, first_bar: 1, bar_numbers: [1, 2, 3], meter_at: meter) }
  let(:identity) { Struct.new(:name, :work, :composer).new("Reading", nil, nil) }
  let(:quarter_at_96) { HeadMusic::Rudiment::Tempo.new("quarter", 96) }
  let(:tempos) do
    {1 => quarter_at_96, 2 => HeadMusic::Rudiment::Tempo.new("quarter", 96.0), 3 => HeadMusic::Rudiment::Tempo.new("quarter", 96, text: "Andante")}
  end
  let(:reading_class) do
    by_bar = tempos
    Class.new(described_class) do
      define_method(:keys) { {} }
      define_method(:tempos) { by_bar }
    end
  end

  it "makes no change where a tempo restates the one in force" do
    expect(flow.tempo_change_at(2)).to be_nil
  end

  it "makes a change where only the tempo's text differs" do
    expect(flow.tempo_change_at(3).text).to eq "Andante"
  end
end
