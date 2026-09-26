require "spec_helper"

describe HeadMusic::Content::Flow::V4Upgrade do
  let(:flow) do
    HeadMusic::Content::Flow.new(name: "Old Song", meter: "3/4").tap do |song|
      voice = song.add_voice(role: "melody")
      voice.place("1:1", :half, "C4").sing("la")
      voice.place("1:3", :quarter)
      voice.place("2:1", :quarter, %w[E4 G4])
    end
  end
  let(:v4) { SchemaV4.flow_hash(flow.to_h) }

  it "reads a v4 flow as the flow that wrote it" do
    expect(HeadMusic::Content::Flow.from_v4_h(v4).to_h).to eq flow.to_h
  end

  it "reads a v4 flow with symbol keys" do
    expect(HeadMusic::Content::Flow.from_v4_h(v4.deep_symbolize_keys).to_h).to eq flow.to_h
  end

  it "reads a v4 voice with no placements key" do
    bare = v4.merge("parts" => [{"voices" => [{"role" => nil}]}])
    expect(HeadMusic::Content::Flow.from_v4_h(bare).voices.first.voice_events).to eq []
  end

  it "refuses a document of another version" do
    expect { HeadMusic::Content::Flow.from_v4_h(flow.to_h) }
      .to raise_error(ArgumentError, "expected schema_version 4, got 5")
  end

  it "refuses a non-Hash" do
    expect { HeadMusic::Content::Flow.from_v4_h("nope") }.to raise_error(ArgumentError, /expected a Hash, got String/)
  end
end
