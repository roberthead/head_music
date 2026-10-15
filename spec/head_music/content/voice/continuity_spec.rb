require "spec_helper"

describe HeadMusic::Content::Voice::Continuity do
  subject(:continuity) { described_class.new(flow, voice.voice_events) }

  let(:flow) { HeadMusic::Content::Flow.new }
  let(:voice) { flow.add_voice }

  def place_in_turn(*values)
    values.each { |value| voice.place(voice.next_position, value, "C4") }
  end

  it "finds no gap in a bar of septuplets" do
    septuplet = HeadMusic::Rudiment::RhythmicValue.get(:sixteenth, tuplet: "7:4")
    place_in_turn(*Array.new(28, septuplet))
    expect([continuity.first_gap, voice.next_position.to_s]).to eq [nil, "2:1:000"]
  end

  it "finds no gap in a bar of triplets and quintuplets" do
    triplet = HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "3:2")
    quintuplet = HeadMusic::Rudiment::RhythmicValue.get(:sixteenth, tuplet: "5:4")
    place_in_turn(*Array.new(6, triplet), *Array.new(10, quintuplet))
    expect([continuity.first_gap, voice.next_position.to_s]).to eq [nil, "2:1:000"]
  end

  it "finds the gap after a septuplet that does not finish its beat" do
    septuplet = HeadMusic::Rudiment::RhythmicValue.get(:sixteenth, tuplet: "7:4")
    place_in_turn(*Array.new(6, septuplet))
    voice.place("1:2", :quarter, "D4")
    expect(continuity.first_gap.first.to_s).to eq "1:1:822:206"
  end
end
