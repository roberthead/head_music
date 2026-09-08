require "spec_helper"

# A score is the layout that shows the players together, so the question it
# answers that no other layout does is what order they go in.
describe HeadMusic::Content::Score do
  subject(:score) { project.add_score(ensemble_type: :orchestral) }

  let(:project) { LayoutFixtures.mixed_ensemble }
  let(:player_names) { score.ordered_players.map(&:name) }

  describe "#kind" do
    it "is a score whatever else it was asked for" do
      expect(described_class.new(project: project, kind: :part).kind).to eq :score
    end
  end

  describe "#ensemble_type" do
    it "must be an order the gem knows" do
      expect { project.add_score(ensemble_type: :marching_kazoos) }
        .to raise_error ArgumentError, /unknown ensemble type/
    end

    it "names the orders it does know" do
      expect { project.add_score(ensemble_type: :marching_kazoos) }
        .to raise_error ArgumentError, /orchestral/
    end

    it "may be absent" do
      expect(project.add_score.score_order).to be_nil
    end
  end

  describe "#ordered_players" do
    it "puts the woodwinds above the strings" do
      expect(player_names).to eq %w[Flute Clarinet Violin Singer]
    end

    it "reorders for the ensemble the score is for" do
      expect(project.add_score(ensemble_type: :string_quartet).ordered_players.map(&:name))
        .to eq %w[Violin Clarinet Singer Flute]
    end

    it "leaves a chair the ensemble has no place for at the bottom" do
      band = project.add_score(ensemble_type: :band)
      expect(band.player_groups.last).to eq [nil, band.ordered_players.last(2)]
    end

    it "is a permutation of the project's players, never a selection" do
      expect(score.ordered_players.sort_by { |player| project.players.index(player) })
        .to eq project.players
    end

    it "leaves a chair with no instrument at the bottom" do
      expect(player_names.last).to eq "Singer"
    end

    it "keeps the authored order between two players of one instrument" do
      second = project.add_player(name: "Clarinet 2")
      project.flows.first.add_part(player: second, instrument: "clarinet").add_voice(role: "clarinet")
      expect(score.ordered_players.map(&:name).grep(/Clarinet/)).to eq ["Clarinet", "Clarinet 2"]
    end

    it "keeps the authored order where no ensemble is named" do
      expect(project.add_score.ordered_players).to eq project.players
    end
  end

  describe "#player_groups" do
    it "groups the chairs into sections, the unplaced ones last" do
      expect(score.player_groups.map(&:first)).to eq [:woodwind, :string, nil]
    end

    it "holds every player exactly once" do
      expect(score.player_groups.flat_map(&:last)).to eq score.ordered_players
    end

    it "is one group where no ensemble is named" do
      expect(project.add_score.player_groups.map(&:first)).to eq [nil]
    end
  end

  describe "rendering" do
    it "lists the parts in score order" do
      document = parse_musicxml(score.to_musicxml)
      expect(xpath_texts(document, "//part-list/score-part/part-name"))
        .to eq %w[Flute Clarinet Violin Singer]
    end

    it "renders every selected player's staff" do
      expect(score.to_lilypond.scan("\\new Staff").length).to eq 4
    end
  end

  describe "serialization" do
    subject(:restored) { HeadMusic::Content::Project.from_h(project.to_h).layouts.first }

    before { score }

    it "reads back as a score" do
      expect(restored).to be_a described_class
    end

    it "keeps its ensemble type" do
      expect(restored.ensemble_type).to eq :orchestral
    end

    it "round-trips losslessly" do
      expect(HeadMusic::Content::Project.from_h(project.to_h).to_h).to eq project.to_h
    end

    it "reads a score that names no ensemble" do
      plain = HeadMusic::Content::Project.new(name: "Plain")
      plain.add_score
      expect(HeadMusic::Content::Project.from_h(plain.to_h).layouts.first.ensemble_type).to be_nil
    end
  end
end
