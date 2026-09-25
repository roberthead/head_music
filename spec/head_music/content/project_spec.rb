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

    context "when a part already carries a player of its own" do
      let(:soprano) { HeadMusic::Content::Player.new(name: "Soprano") }

      before { flow.parts.first.player = soprano }

      it "keeps the part's player" do
        project.add_flow(flow)
        expect(flow.parts.first.player).to be soprano
      end

      it "adopts the player into the project's chairs" do
        project.add_flow(flow)
        expect(project.players).to eq [soprano, flow.parts.last.player]
      end

      it "gives the player to the project" do
        project.add_flow(flow)
        expect(soprano.project).to be project
      end

      it "adopts a player shared by two parts once" do
        flow.parts.last.player = soprano
        project.add_flow(flow)
        expect(project.players).to eq [soprano]
      end

      it "adopts a player shared across two flows once" do
        second = HeadMusic::Content::Flow.new(name: "II")
        second.add_part(player: soprano).add_voice
        project.add_flow(flow)
        project.add_flow(second)
        expect(project.players.count { |player| player.equal?(soprano) }).to eq 1
      end
    end

    context "when a part's player belongs to another project" do
      before { flow.parts.first.player = described_class.new.add_player(name: "Oboe") }

      it "refuses the flow" do
        expect { project.add_flow(flow) }.to raise_error ArgumentError, /player belongs to another project/
      end

      it "takes nothing from the flow it refuses" do
        expect { project.add_flow(flow) }.to raise_error(ArgumentError)
        expect([project.flows, project.players, flow.project]).to eq [[], [], nil]
      end
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
