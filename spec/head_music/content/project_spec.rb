require "spec_helper"

describe HeadMusic::Content::Project do
  subject(:project) { described_class.new(name: "Suite") }

  its(:name) { is_expected.to eq "Suite" }
  its(:players) { is_expected.to be_empty }
  its(:flows) { is_expected.to be_empty }

  it "names itself when unnamed" do
    expect(described_class.new.name).to eq "Project"
  end

  describe "#add_player" do
    it "returns a player belonging to the project" do
      expect(project.add_player(name: "Piano").project).to be project
    end

    it "keeps players in the order they were authored" do
      project.add_player(name: "Cello")
      project.add_player(name: "Flute")
      expect(project.players.map(&:name)).to eq %w[Cello Flute]
    end
  end

  describe "#to_s" do
    it "counts one flow" do
      project.flows << HeadMusic::Content::Flow.new
      expect(project.to_s).to eq "Suite — 1 flow"
    end

    it "counts several flows" do
      project.flows.push(HeadMusic::Content::Flow.new, HeadMusic::Content::Flow.new)
      expect(project.to_s).to eq "Suite — 2 flows"
    end
  end

  describe "#add_flow" do
    let(:flow) { HeadMusic::Content::Flow.new(name: "I") }

    before do
      flow.add_part(instrument: "flute").add_voice
      flow.add_part.add_voice
    end

    it "takes ownership of the flow" do
      expect(project.add_flow(flow).project).to be project
    end

    it "holds the flow" do
      project.add_flow(flow)
      expect(project.flows).to eq [flow]
    end

    it "mints a player for each part that has none" do
      project.add_flow(flow)
      expect(flow.parts.map { |part| part.player.name }).to eq ["flute", "Part 2"]
    end

    it "names each minted player for what it plays, or for where it sits" do
      project.add_flow(flow)
      expect(project.players.map(&:name)).to eq ["flute", "Part 2"]
    end

    it "leaves a part that already had a player alone" do
      player = project.add_player(name: "Piccolo")
      flow.parts.first.player = player
      project.add_flow(flow)
      expect(flow.parts.first.player).to be player
    end

    it "adopts a flow it already owns without minting more players" do
      project.add_flow(flow)
      expect { project.add_flow(flow) }.not_to change { project.players.length }
    end

    it "refuses a flow another project owns" do
      project.add_flow(flow)
      expect { described_class.new.add_flow(flow) }
        .to raise_error ArgumentError, /belongs to another project/
    end
  end

  describe "a player's instruments" do
    let(:flow) { HeadMusic::Content::Flow.new }

    before do
      part = flow.add_part(instrument: "flute")
      part.change_instrument(9, "piccolo")
      project.add_flow(flow)
    end

    # Derived from the parts rather than stored, so it cannot drift from the
    # instrument changes that are authored on them.
    it "is every instrument its parts carry" do
      expect(project.players.first.instruments.map(&:name)).to eq ["flute", "piccolo flute"]
    end

    it "picks up the one in force at the opening of its first part" do
      expect(project.players.first.primary_instrument.name).to eq "flute"
    end
  end
end
