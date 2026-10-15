require "spec_helper"

describe HeadMusic::MIDI::ChannelAllocator do
  subject(:allocator) { described_class.new(flow) }

  let(:flow) { HeadMusic::Content::Flow.new }

  def add_part(instrument = nil, sound: "C4")
    flow.add_part(instrument: instrument).tap { |part| part.add_voice.place("1:1", :whole, sound) }
  end

  def channels
    flow.parts.map { |part| allocator.channel_for(part) }
  end

  it "gives pitched parts channels in part order" do
    %w[flute oboe clarinet].each { |name| add_part(name) }
    expect(channels).to eq [0, 1, 2]
  end

  it "passes over the percussion channel" do
    %w[violin viola cello double_bass flute oboe clarinet bassoon french_horn trumpet].each { |name| add_part(name) }
    expect(channels.last(2)).to eq [8, 10]
  end

  it "gives a part of unpitched sounds no pitched channel" do
    add_part("snare_drum", sound: "snare drum")
    expect(channels).to eq [nil]
  end

  it "gives a part of rests no channel" do
    add_part("flute", sound: nil)
    expect(channels).to eq [nil]
  end

  it "gives a part pitched only in its grace notes a channel" do
    part = add_part("snare_drum", sound: "snare drum")
    part.voices.first.voice_events.first.add_grace_note("C4", :eighth)
    expect(channels).to eq [0]
  end

  it "counts a part pitched by its sounds, though its instrument's notation is not" do
    add_part("timpani", sound: "C3")
    expect(channels).to eq [0]
  end

  it "shares a channel among parts of one instrument" do
    %w[violin viola violin].each { |name| add_part(name) }
    expect(channels).to eq [0, 1, 0]
  end

  it "does not share a channel with a part that changes instrument" do
    add_part("clarinet")
    add_part("clarinet").change_instrument(3, "clarinet_in_a")
    expect(channels).to eq [0, 1]
  end

  it "does not share a channel among parts with no instrument" do
    2.times { add_part }
    expect(channels).to eq [0, 1]
  end

  it "refuses more distinct pitched parts than channels, naming the count" do
    17.times { add_part }
    expect { allocator }.to raise_error(HeadMusic::MIDI::RenderError, /needs 17 pitched channels, and MIDI has 15/)
  end
end
