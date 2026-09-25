require "spec_helper"

# A project round-trips its chairs, its flows, and which chair each part fills.
# A player has no identity of its own beyond its place in the authored order,
# so that index is what the document carries.
describe HeadMusic::Content::Project do
  subject(:project) { described_class.new(name: "Suite") }

  let(:staff_system) { HeadMusic::Content::StaffSystem.grand_staff }

  before do
    first = HeadMusic::Content::Flow.new(name: "I", key_signature: "D dorian", meter: "4/4")
    piano = first.add_part(instrument: "piano", staff_system: staff_system)
    piano.change_instrument(9, "celesta")
    left_hand = piano.add_voice(role: "left hand")
    left_hand.place("1:1", :whole, "C3")
    left_hand.cross_to(staff_system.staves.last, from: 1)
    left_hand.cross_to(staff_system.staves.first, from: 5)
    left_hand.cross_to(staff_system.staves.last, from: 7)
    first.add_part(instrument: "flute").add_voice(role: "flute").place("1:1", :whole, "C5")
    first.bars(2).last.starts_repeat = true
    first.change_key_signature(5, -3, tonal_context: HeadMusic::Rudiment::Mode.get("C dorian"))

    second = HeadMusic::Content::Flow.new(name: "II")
    second.add_part(instrument: "flute").add_voice(role: "flute").place("1:1", :whole, "G4")

    project.add_flow(first)
    project.add_flow(second)

    project.add_layout(kind: :score)
    project.add_layout(
      kind: :part, flows: [first], players: [project.players.first],
      concert_pitch: false, title_override: "Keyboard"
    )
  end

  it "round-trips losslessly" do
    expect(described_class.from_h(project.to_h).to_h).to eq project.to_h
  end

  it "round-trips through JSON" do
    expect(described_class.from_json(project.to_json).to_h).to eq project.to_h
  end

  it "refuses a layout that selects a player the document does not hold" do
    document = project.to_h
    document["layouts"].last["players"] = [9]
    expect { described_class.from_h(document) }
      .to raise_error ArgumentError, /selects a player the project does not hold/
  end

  describe "what survives the round trip" do
    subject(:restored) { described_class.from_h(project.to_h) }

    it "keeps each layout's class" do
      expect(restored.layouts.map(&:class)).to eq [HeadMusic::Content::Score, HeadMusic::Content::Layout]
    end

    it "keeps the players in authored order" do
      expect(restored.players.map(&:name)).to eq project.players.map(&:name)
    end

    it "keeps the flows in order" do
      expect(restored.flows.map(&:name)).to eq %w[I II]
    end

    it "puts each part back in its chair" do
      expect(restored.flows.first.parts.map { |part| part.player.name })
        .to eq project.flows.first.parts.map { |part| part.player.name }
    end

    it "gives a player back the parts across flows that are theirs" do
      expect(restored.players.map { |player| player.parts.length })
        .to eq project.players.map { |player| player.parts.length }
    end

    it "keeps the instrument changes" do
      expect(restored.flows.first.parts.first.instruments.map(&:name)).to eq %w[piano celesta]
    end

    it "keeps the staff assignments" do
      expect(restored.flows.first.voices.first.staff_assignments.keys).to eq [1, 5, 7]
    end

    it "keeps the crossing, staff for staff" do
      voice = restored.flows.first.voices.first
      system = restored.flows.first.parts.first.staff_system
      expect((1..8).map { |bar| system.staves.index { |staff| staff.equal?(voice.staff_at(bar)) } })
        .to eq [1, 1, 1, 1, 0, 0, 1, 1]
    end

    it "keeps the repeat structure" do
      expect(restored.flows.first.bars(2).last.starts_repeat?).to be true
    end

    it "keeps a key signature that diverges from its printed signature" do
      timeline = restored.flows.first.timeline
      expect([timeline.signature_at(5), timeline.tonal_context_at(5).name]).to eq [-3, "C dorian"]
    end
  end

  # A layout selects flows and players by their place in the project's authored
  # order, which is the only identity either has.
  describe "layouts" do
    subject(:restored) { described_class.from_h(project.to_h) }

    it "restores both layouts" do
      expect(restored.layouts.map(&:kind)).to eq %i[score part]
    end

    it "restores an unselected layout as one that answers everything" do
      expect(restored.layouts.first.flows.length).to eq restored.flows.length
    end

    it "restores a selection to the project's own flows" do
      expect(restored.layouts.last.flows).to eq [restored.flows.first]
    end

    it "restores a selection to the project's own players" do
      expect(restored.layouts.last.players).to eq [restored.players.first]
    end

    it "restores the title override" do
      expect(restored.layouts.last.title).to eq "Keyboard"
    end

    it "restores the written-pitch flag" do
      expect(restored.layouts.map(&:concert_pitch?)).to eq [true, false]
    end

    it "reads a document written before layouts existed" do
      hash = project.to_h.except("layouts")
      expect(described_class.from_h(hash).layouts).to be_empty
    end
  end

  describe "schema_version" do
    it "carries version 4" do
      expect(project.to_h["schema_version"]).to eq 4
    end

    it "refuses another version" do
      expect { described_class.from_h({"schema_version" => 3}) }
        .to raise_error ArgumentError, /unsupported schema_version: 3 \(supported: 4\)/
    end

    it "refuses non-Hash input" do
      expect { described_class.from_h("nope") }.to raise_error ArgumentError, /expected a Hash/
    end
  end

  # The chunk of music that does not live inside a project: a flow is its own
  # document, and needs no project to be one.
  describe "a standalone flow" do
    subject(:flow) { HeadMusic::Content::CantusFirmus::Example.all.first.to_flow }

    it "has no project" do
      expect(flow.project).to be_nil
    end

    it "round-trips as its own document" do
      expect(HeadMusic::Content::Flow.from_h(flow.to_h).to_h).to eq flow.to_h
    end
  end

  # A flow that names its chairs before a project holds it keeps those names
  # once adopted. The project's own indexes stay the one record of them.
  describe "a flow adopted with players of its own" do
    subject(:restored) { described_class.from_h(chorale_project.to_h) }

    let(:chorale_project) { described_class.new(name: "Chorales").tap { |chorales| chorales.add_flow(chorale) } }
    let(:chorale) do
      HeadMusic::Content::Flow.from_h(
        HeadMusic::Content::Flow.new(name: "Chorale").tap { |flow|
          flow.add_part(player: HeadMusic::Content::Player.new(name: "Soprano")).add_voice.place("1:1", :whole, "C5")
          flow.add_part(player: HeadMusic::Content::Player.new(name: "Bass")).add_voice.place("1:1", :whole, "C3")
        }.to_h
      )
    end

    it "keeps the adopted players" do
      expect(restored.players.map(&:name)).to eq %w[Soprano Bass]
    end

    it "pairs each part with the project's own player" do
      expect(restored.flows.first.parts.map(&:player)).to eq restored.players
    end

    it "lets a layout select an adopted player" do
      chorale_project.add_layout(kind: :part, players: [chorale_project.players.last])
      expect(restored.layouts.last.players.map(&:name)).to eq ["Bass"]
    end

    it "writes no part players into the project document" do
      flow_hash = chorale_project.to_h["flows"].first
      expect([flow_hash.key?("part_players"), flow_hash["parts"].map { |part| part.key?("player") }])
        .to eq [false, [false, false]]
    end

    it "trusts the project's indexes over a flow's own players" do
      document = chorale_project.to_h
      document["flows"].first.merge!("part_players" => [{"name" => "Stray"}], "players" => [1, nil])
      document["flows"].first["parts"].first["player"] = 0
      expect(described_class.from_h(document).flows.first.parts.map { |part| part.player&.name }).to eq ["Bass", nil]
    end
  end
end
