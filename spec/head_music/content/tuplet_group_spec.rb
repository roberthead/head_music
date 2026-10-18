require "spec_helper"

describe HeadMusic::Content::TupletGroup do
  subject(:group) { described_class.new(voice, from: "1:1", to: "1:2") }

  let(:flow) { HeadMusic::Content::Flow.new }
  let(:voice) { flow.add_voice }
  let(:triplet_eighth) { HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "3:2") }

  before { 6.times { voice.place(voice.next_position, triplet_eighth, "C4") } }

  its(:ratio) { is_expected.to eq HeadMusic::Rudiment::TupletRatio.get("3:2") }
  its(:to_s) { is_expected.to eq "3:2 tuplet from 1:1:000 to 1:2:000" }
  its(:inspect) { is_expected.to eq "#<HeadMusic::Content::TupletGroup 3:2 tuplet from 1:1:000 to 1:2:000>" }
  its(:to_h) { is_expected.to eq("from" => "1:1:000", "to" => "1:2:000", "unit" => "eighth") }

  it { is_expected.to be_frozen }

  it "covers its half-open span" do
    expect(%w[1:1 1:1:959 1:2].map { |code| group.covers?(flow.position(code)) }).to eq [true, true, false]
  end

  it "orders by start, then end" do
    later = described_class.new(voice, from: "1:2", to: "1:3")
    expect([later, group].sort).to eq [group, later]
  end

  it "does not overlap a group it touches" do
    expect(group.overlaps?(described_class.new(voice, from: "1:2", to: "1:3"))).to be false
  end

  it "refuses a position from another flow" do
    expect { described_class.new(voice, from: HeadMusic::Content::Flow.new.position("1:1"), to: "1:2") }
      .to raise_error(ArgumentError, "position belongs to a different flow")
  end

  it "has no links where no event sounds" do
    expect(described_class.links_between(voice, flow.position("5:1"), flow.position("6:1"))).to be_empty
  end

  it "has the chain links of a voice event" do
    expect(described_class.links_of(voice.last_voice_event)).to eq HeadMusic::Content::ChainLink.of(voice.last_voice_event)
  end

  it "reads its links as the bracket it was made from holds them" do
    expect(group.links).to eq described_class::Bracketing.new(voice, group.from, group.to).links
  end
end
