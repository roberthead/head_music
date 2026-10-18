require "spec_helper"

describe HeadMusic::Notation::ABC::PendingSlurs do
  subject(:slurs) { described_class.new(voice) }

  let(:voice) { HeadMusic::Content::Flow.new.add_voice(role: nil) }
  let(:pitch) { HeadMusic::Rudiment::Pitch.get("C4") }

  def place(marks)
    voice_event = voice.place(voice.next_position, :quarter, [pitch])
    slurs.apply(voice_event, marks)
  end

  it "takes the slurs opened ahead of the next note" do
    2.times { slurs.open }
    expect([slurs.take, slurs.take]).to eq [%i[open open], []]
  end

  it "starts a slur opened before grace notes on them" do
    slurs.open
    slurs.start_on_graces
    expect(slurs.take).to eq [:grace_open]
  end

  it "starts it after the grace notes once they are dropped" do
    slurs.open
    slurs.start_on_graces
    slurs.start_after_graces
    expect(slurs.take).to eq [:open]
  end

  it "pairs slurs by nesting" do
    place([:open])
    place([:open])
    place([:close])
    place([:close])
    expect(voice.spans.map(&:to_s)).to eq ["slur from 1:1:000 to 1:4:000", "slur from 1:2:000 to 1:3:000"]
  end

  it "drops a slur that spans nothing" do
    place(%i[open close])
    expect(voice.spans).to be_empty
  end

  it "keeps a slur from grace notes to their own main note" do
    voice_event = voice.place(voice.next_position, :quarter, [pitch])
    voice_event.add_grace_note(HeadMusic::Rudiment::Pitch.get("D4"), :eighth)
    slurs.apply(voice_event, %i[grace_open close])
    expect(voice.spans.length).to eq 1
  end

  it "drops a close with no open slur" do
    place([:close])
    expect(voice.spans).to be_empty
  end
end
