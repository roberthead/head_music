require "spec_helper"

describe HeadMusic::Content::VoiceEvents do
  subject(:voice_events) { described_class.new }

  let(:voice) { HeadMusic::Content::Voice.new }

  def event(position, rhythmic_value = :quarter, sounds = "C4")
    HeadMusic::Content::VoiceEvent.build(voice, position, rhythmic_value, sounds)
  end

  def position(code)
    voice.flow.position(code)
  end

  before do
    [event("1:3"), event("1:1", :half), event("2:1", :whole, nil)].each { |voice_event| voice_events.place(voice_event) }
  end

  it "keeps its events in position order" do
    expect(voice_events.map { |voice_event| voice_event.position.to_s }).to eq %w[1:1:000 1:3:000 2:1:000]
  end

  it "merges an event placed where one already is" do
    voice_events.place(event("1:3", :quarter, "E4"))
    expect(voice_events.at(position("1:3")).pitches.map(&:to_s)).to eq %w[C4 E4]
  end

  it "answers the event starting at a position" do
    expect(voice_events.at(position("1:3")).position).to eq position("1:3")
  end

  it "answers nothing at a position where no event starts" do
    expect(voice_events.at(position("1:2"))).to be_nil
  end

  it "answers the first event at or after a position" do
    expect(voice_events.starting_from(position("1:2")).position).to eq position("1:3")
  end

  it "answers the event still sounding at a position" do
    expect(voice_events.sounding_at(position("1:2")).position).to eq position("1:1")
  end

  it "answers nothing after its last event ends" do
    expect(voice_events.sounding_at(position("3:1"))).to be_nil
  end
end
