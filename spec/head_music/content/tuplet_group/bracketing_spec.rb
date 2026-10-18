require "spec_helper"

describe HeadMusic::Content::TupletGroup::Bracketing do
  let(:flow) { HeadMusic::Content::Flow.new }
  let(:voice) { flow.add_voice }
  let(:triplet_eighth) { HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "3:2") }

  def bracketing(from, to)
    described_class.new(voice, flow.position(from), flow.position(to))
  end

  def starts(links)
    links.map { |link| link.voice_event.position.to_s }
  end

  before { 6.times { voice.place(voice.next_position, triplet_eighth, "C4") } }

  it "holds the links from its start up to its end" do
    expect(starts(bracketing("1:1", "1:2").links)).to eq %w[1:1:000 1:1:320 1:1:640]
  end

  it "answers the ratio of the links it holds" do
    expect(bracketing("1:1", "1:2").ratio).to eq HeadMusic::Rudiment::TupletRatio.get("3:2")
  end

  it "is frozen" do
    expect(bracketing("1:1", "1:2")).to be_frozen
  end

  it "refuses a span that starts inside a note" do
    expect { bracketing("1:1:100", "1:2") }.to raise_error(ArgumentError, /must start where a note, rest, or tied link starts/)
  end

  it "refuses a span that ends inside a note" do
    expect { bracketing("1:1", "1:1:900") }.to raise_error(ArgumentError, /must end where a note, rest, or tied link ends/)
  end

  describe ".links_inside" do
    it "reads the links of a bracket already made" do
      expect(starts(described_class.links_inside(voice, flow.position("1:2"), flow.position("1:3")))).to eq %w[1:2:000 1:2:320 1:2:640]
    end
  end
end
