require "spec_helper"

describe HeadMusic::Content::Flow::HashSerializer do
  let(:flow) { HeadMusic::Content::Flow.new(name: "Chorale", composer: "Anonymous") }

  def serialize
    flow.to_h
  end

  it "writes the schema version first" do
    expect(serialize.keys.first).to eq "schema_version"
  end

  it "writes the flow's own fields" do
    expect(serialize.slice("schema_version", "name", "composer"))
      .to eq("schema_version" => HeadMusic::Content::Flow::SCHEMA_VERSION, "name" => "Chorale", "composer" => "Anonymous")
  end

  it "leaves out part players when no part has one" do
    flow.add_voice
    expect(serialize).not_to have_key("part_players")
  end

  it "writes a player two parts share once, pointing both parts at it" do
    player = HeadMusic::Content::Player.new(name: "Keys")
    2.times { flow.add_part(player: player) }
    expect([serialize["part_players"], serialize["parts"].map { |part| part["player"] }]).to eq [[{"name" => "Keys"}], [0, 0]]
  end

  it "reads back as the flow it wrote" do
    flow.add_voice.place("1:1", :whole, "C4")
    expect(HeadMusic::Content::Flow.from_h(serialize).to_h).to eq serialize
  end
end
