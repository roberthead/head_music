require "spec_helper"

# The fixture was written by head_music 22 before RhythmicDuration existed,
# so it pins the serialized form saved flows already hold.
describe HeadMusic::Content::Flow do
  let(:path) { File.expand_path("../../fixtures/content/flow_with_tied_values.json", __dir__) }
  let(:hash) { JSON.parse(File.read(path)) }
  let(:flow) { described_class.from_h(hash) }
  let(:voice_events) { flow.voices.first.voice_events }

  let(:expected_spans) do
    [
      ["1:1:000", "1:2:480"],
      ["1:2:480", "1:3:000"],
      ["1:3:000", "2:1:480"],
      ["2:1:480", "2:2:480"],
      ["2:2:480", "2:3:240"],
      ["2:3:240", "3:1:000"],
      ["3:1:000", "3:2:000"],
      ["3:2:000", "3:2:320"],
      ["3:2:320", "3:3:000"],
      ["3:3:000", "4:1:000"],
      ["4:1:000", "6:1:000"]
    ]
  end

  it "loads tied values saved by an earlier release" do
    expect(voice_events.map { |event| [event.position.to_s, event.next_position.to_s] }).to eq expected_spans
  end

  it "keeps each tied name as it was written" do
    names = hash["parts"].first["voices"].first["voice_events"].map { |event| event["rhythmic_value"] }

    expect(names).to include("half tied to eighth", "sixteenth tied to quarter tied to eighth", "triplet eighth tied to triplet quarter", "whole tied to whole")
  end

  it "writes the flow back unchanged" do
    expect(flow.to_h).to eq hash
  end
end
