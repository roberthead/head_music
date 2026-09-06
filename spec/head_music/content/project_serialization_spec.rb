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
  end

  it "round-trips losslessly" do
    expect(described_class.from_h(project.to_h).to_h).to eq project.to_h
  end

  it "round-trips through JSON" do
    expect(described_class.from_json(project.to_json).to_h).to eq project.to_h
  end

  describe "what survives the round trip" do
    subject(:restored) { described_class.from_h(project.to_h) }

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
end
