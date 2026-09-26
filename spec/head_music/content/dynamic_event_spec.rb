require "spec_helper"

describe HeadMusic::Content::DynamicEvent do
  let(:flow) { HeadMusic::Content::Flow.new }

  it "holds a level at a position" do
    dynamic_event = described_class.new(flow, "5:1", :f)
    expect(dynamic_event.to_s).to eq "f at 5:1:000"
  end

  it "answers its level as a dynamic" do
    expect(described_class.new(flow, "1:1", "MP").level).to be HeadMusic::Rudiment::Dynamic.get(:mp)
  end

  it "refuses an accent" do
    expect { described_class.new(flow, "1:1", :sfz) }
      .to raise_error(ArgumentError, "sfz is an accent, not a level; set it as a note event's note_dynamic")
  end

  it "refuses an unknown dynamic" do
    expect { described_class.new(flow, "1:1", :loud) }.to raise_error(ArgumentError, "unknown dynamic: :loud")
  end

  it "accepts a position in its own flow" do
    position = flow.position("2:3")
    expect(described_class.new(flow, position, :p).position).to be position
  end

  it "refuses a position from another flow" do
    position = HeadMusic::Content::Flow.new.position("2:3")
    expect { described_class.new(flow, position, :p) }
      .to raise_error(ArgumentError, "position belongs to a different flow")
  end

  it "serializes its position and level" do
    expect(described_class.new(flow, "5:1", :f).to_h).to eq("position" => "5:1:000", "level" => "f")
  end

  it "inspects as its class and description" do
    expect(described_class.new(flow, "5:1", :f).inspect).to eq "#<HeadMusic::Content::DynamicEvent f at 5:1:000>"
  end
end
