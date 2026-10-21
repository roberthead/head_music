require "spec_helper"

describe HeadMusic::Content::Flow::TimelineSerializer do
  subject(:hash) { described_class.new(flow.timeline).to_h }

  let(:flow) { HeadMusic::Content::Flow.new(meter: "4/4", tempo: HeadMusic::Rudiment::Tempo.new("quarter", 96)) }

  it "writes the opening values and each kind of change, in schema order" do
    expect(hash.keys).to eq %w[meter key_signature tempo meter_changes key_signature_changes tempo_changes tempo_ramps a_tempos fermatas]
  end

  it "writes a meter's symbol beside its numerals" do
    flow.change_meter(3, HeadMusic::Rudiment::Meter.common_time)
    expect(hash["meter_changes"]).to eq [{"number" => 3, "meter" => "4/4", "symbol" => "common"}]
  end

  it "writes a tempo's text, and a tempo with no metronome mark" do
    flow.change_tempo(2, HeadMusic::Rudiment::Tempo.new("quarter", 72, text: "Adagio", metronome_mark: false))
    expect(hash["tempo_changes"].first["tempo"])
      .to eq("beat_value" => "quarter", "beats_per_minute" => 72, "text" => "Adagio", "metronome_mark" => false)
  end

  it "writes a ramp with no target or text as its ends alone" do
    flow.add_tempo_ramp(from: "2:3", to: "4:1")
    expect(hash["tempo_ramps"]).to eq [{"from" => "2:3:000", "to" => "4:1:000"}]
  end

  it "writes a whole-number stretch as an Integer" do
    flow.add_fermata("2:1", to: "2:2", stretch: 2.0)
    expect(hash["fermatas"]).to eq [{"from" => "2:1:000", "to" => "2:2:000", "stretch" => 2}]
  end
end
