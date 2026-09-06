require "spec_helper"

# v3 restructured into v4, so no key-rename recipe can migrate persisted
# documents in place the way v2 to v3 was migrated. The reader is retained
# read-only through 21.x so an application can migrate by reading and
# re-saving, rather than by loading two gem versions at once.
describe HeadMusic::Content::Flow::V3HashDeserializer do
  subject(:flow) { HeadMusic::Content::Flow.from_v3_h(hash) }

  let(:hash) do
    {
      "schema_version" => 3,
      "name" => "Legacy Tune",
      "key_signature" => "D major",
      "meter" => "4/4",
      "composer" => "Trad.",
      "origin" => "Nowhere",
      "voices" => [
        {"role" => "melody", "placements" => [
          {"position" => "1:1:000", "rhythmic_value" => "half", "sounds" => ["D4"]},
          {"position" => "1:3:000", "rhythmic_value" => "half", "sounds" => ["F#4"]}
        ]},
        {"role" => "bass", "placements" => [
          {"position" => "1:1:000", "rhythmic_value" => "whole", "sounds" => ["D3"]}
        ]}
      ],
      "bars" => [
        {"number" => 2, "key_signature" => "A major", "meter" => "3/4", "starts_repeat" => true}
      ],
      "comments" => [{"text" => "from the old schema", "position" => "1:1:000"}]
    }
  end

  it "reads the flow's identity" do
    expect([flow.name, flow.composer, flow.origin]).to eq ["Legacy Tune", "Trad.", "Nowhere"]
  end

  it "reads the opening key signature and meter onto the timeline" do
    expect([flow.key_signature.name, flow.meter.to_s]).to eq ["D major", "4/4"]
  end

  it "reads a bar's key change onto the timeline" do
    expect(flow.key_signature_at(2).name).to eq "A major"
  end

  it "reads a bar's meter change onto the timeline" do
    expect(flow.meter_at(2).to_s).to eq "3/4"
  end

  it "reads the repeat structure" do
    expect(flow.bars(2).last.starts_repeat?).to be true
  end

  # Every concept v3 replays has a home in the new model: a v3 voice becomes a
  # part holding one voice, which is what Flow#add_voice already mints.
  it "gives each v3 voice a part of its own" do
    expect(flow.parts.length).to eq 2
  end

  it "puts one voice in each part" do
    expect(flow.parts.map { |part| part.voices.length }).to eq [1, 1]
  end

  it "keeps the voices and their roles in order" do
    expect(flow.voices.map(&:role)).to eq %w[melody bass]
  end

  it "reads the placements" do
    expect(flow.voices.first.pitches.map(&:to_s)).to eq ["D4", "F♯4"]
  end

  it "reads the comments" do
    expect(flow.comments.map(&:text)).to eq ["from the old schema"]
  end

  # The migration an application performs: read the old row, save the new one.
  it "re-saves as a schema 4 document" do
    expect(flow.to_h["schema_version"]).to eq 4
  end

  it "survives the re-save unchanged" do
    expect(HeadMusic::Content::Flow.from_h(flow.to_h).to_h).to eq flow.to_h
  end

  it "refuses a v4 document" do
    expect { HeadMusic::Content::Flow.from_v3_h(hash.merge("schema_version" => 4)) }
      .to raise_error ArgumentError, /unsupported schema_version: 4 \(supported: 3\)/
  end
end
