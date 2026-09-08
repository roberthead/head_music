require "spec_helper"

# A layout selects; it does not author. Nothing it answers is stored twice, and
# nothing it realizes reaches back into the project's own flows.
describe HeadMusic::Content::Layout do
  subject(:layout) { project.add_layout }

  let(:project) { LayoutFixtures.suite }
  let(:flute) { project.players.first }
  let(:violin) { project.players.last }

  describe "kind" do
    its(:kind) { is_expected.to eq :custom }

    it "accepts every known kind" do
      expect(described_class::KINDS.map { |kind| project.add_layout(kind: kind).kind })
        .to eq described_class::KINDS
    end

    it "refuses a kind it does not know" do
      expect { project.add_layout(kind: :lead_sheet) }
        .to raise_error ArgumentError, /unknown layout kind: :lead_sheet/
    end

    it "answers a score for the score kind" do
      expect(project.add_layout(kind: :score)).to be_a HeadMusic::Content::Score
    end

    it "leaves the score kind to Score" do
      expect { described_class.new(project: project, kind: :score) }
        .to raise_error ArgumentError, /unknown layout kind: :score/
    end
  end

  describe "selection" do
    it "answers every flow when none were selected" do
      expect(layout.flows).to eq project.flows
    end

    it "answers every player when none were selected" do
      expect(layout.players).to eq project.players
    end

    it "keeps answering the project's flows as flows are added" do
      project.add_flow(HeadMusic::Content::Flow.new(name: "IV"))
      expect(layout.flows.map(&:name)).to eq %w[I II III IV]
    end

    it "answers only the flows it was given" do
      selected = project.add_layout(flows: [project.flows.last])
      expect(selected.flows.map(&:name)).to eq %w[III]
    end

    it "answers only the players it was given" do
      expect(project.add_layout(players: [flute]).players).to eq [flute]
    end

    it "refuses a player the project does not hold" do
      stranger = HeadMusic::Content::Project.new(name: "Other").add_player(name: "Stranger")
      expect { project.add_layout(players: [stranger]) }
        .to raise_error ArgumentError, /selects a player the project does not hold/
    end

    it "refuses a flow the project does not hold" do
      expect { project.add_layout(flows: [HeadMusic::Content::Flow.new(name: "Stray")]) }
        .to raise_error ArgumentError, /selects a flow the project does not hold/
    end
  end

  describe "#concert_pitch?" do
    its(:concert_pitch?) { is_expected.to be true }

    it "is false when the layout was written for transposing instruments" do
      expect(project.add_layout(concert_pitch: false).concert_pitch?).to be false
    end
  end

  describe "#rendered_flows" do
    subject(:layout) { project.add_layout(kind: :part, players: [flute]) }

    it "skips a flow the selected player has no part in" do
      expect(layout.rendered_flows.map(&:name)).to eq %w[I III]
    end

    it "renders every flow for a player who plays throughout" do
      expect(project.add_layout(players: [violin]).rendered_flows.map(&:name)).to eq %w[I II III]
    end

    it "renders every flow when no players were selected" do
      expect(project.add_layout.rendered_flows.length).to eq 3
    end
  end

  describe "#title" do
    its(:title) { is_expected.to eq "Suite" }

    it "prefers the override" do
      expect(project.add_layout(title_override: "Flute Book").title).to eq "Flute Book"
    end
  end

  describe "#realize" do
    let(:flow) { project.flows.first }

    it "leaves the source flow alone" do
      part_layout = project.add_layout(kind: :part, players: [flute])
      expect { part_layout.realize(flow) }.not_to change(flow, :to_h)
    end

    it "reproduces a flow it selects nothing away from" do
      expect(layout.realize(flow).to_h).to eq flow.to_h
    end

    it "keeps only the selected player's part" do
      realized = project.add_layout(kind: :part, players: [flute]).realize(flow)
      expect(realized.parts.map { |part| part.player.name }).to eq %w[Flute]
    end

    it "keeps the selected parts in authored order" do
      realized = project.add_layout(players: [violin, flute]).realize(flow)
      expect(realized.parts.map { |part| part.player.name }).to eq %w[Flute Violin]
    end

    it "carries the music of the part it keeps" do
      realized = project.add_layout(kind: :part, players: [flute]).realize(flow)
      expect(realized.voices.first.placements.map { |placement| placement.sounds.first.to_s })
        .to eq %w[C5 D5 E5 F5]
    end
  end

  describe "a part no player fills" do
    let(:flow) { project.flows.first }

    before { flow.add_part(instrument: "viola").add_voice(role: "viola") }

    it "is kept when no players were selected" do
      expect(layout.realize(flow).parts.length).to eq 3
    end

    it "is dropped once players are selected" do
      realized = project.add_layout(players: [flute, violin]).realize(flow)
      expect(realized.parts.length).to eq 2
    end
  end

  describe "#to_h" do
    it "writes a selection as indexes into the project's own order" do
      selected = project.add_layout(kind: :part, flows: [project.flows.last], players: [violin])
      expect(selected.to_h).to eq(
        "kind" => "part", "title_override" => nil, "concert_pitch" => true, "ensemble_type" => nil,
        "flows" => [2], "players" => [1]
      )
    end

    it "writes null for an unselected collection" do
      expect(layout.to_h.values_at("flows", "players")).to eq [nil, nil]
    end
  end

  describe "#to_s" do
    it "counts the flows it renders" do
      expect(project.add_layout(kind: :part, players: [flute]).to_s)
        .to eq "Suite — part layout of 2 flows"
    end
  end
end
