require "spec_helper"

describe HeadMusic::Notation::ABC::InvisibleRests do
  subject(:rests) { described_class.new(voice) }

  let(:voice) { HeadMusic::Content::Flow.new.add_voice(role: nil) }

  it "runs the music's end past the voice events" do
    rests.add(HeadMusic::Rudiment::RhythmicValue.new(:half))
    expect([rests.music_end.to_s, voice.voice_events]).to eq ["1:3:000", []]
  end

  it "says where each one starts and ends" do
    rests.add(HeadMusic::Rudiment::RhythmicValue.new(:half))
    span = rests.add(HeadMusic::Rudiment::RhythmicValue.new(:quarter))
    expect(span.map(&:to_s)).to eq ["1:3:000", "1:4:000"]
  end

  it "reaches past the last voice event's bar only once they cross a bar line" do
    voice.place("1:1", :quarter, "C4")
    rests.add(HeadMusic::Rudiment::RhythmicValue.new(:half))
    within_bar = rests.past_last_bar?
    rests.add(HeadMusic::Rudiment::RhythmicValue.new(:whole))
    expect([within_bar, rests.past_last_bar?]).to eq [false, true]
  end

  it "places them as rests" do
    rests.add(HeadMusic::Rudiment::RhythmicValue.new(:half))
    rests.place
    expect([voice.voice_events.map(&:to_s), rests.any?]).to eq [["half rest at 1:1:000"], false]
  end
end
