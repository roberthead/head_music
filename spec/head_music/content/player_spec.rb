require "spec_helper"

describe HeadMusic::Content::Player do
  subject(:player) { project.add_player(name: "Flute 1") }

  let(:project) { HeadMusic::Content::Project.new(name: "Suite") }

  its(:name) { is_expected.to eq "Flute 1" }
  its(:project) { is_expected.to be project }
  its(:to_s) { is_expected.to eq "Flute 1" }

  describe "#parts" do
    let(:first_movement) { HeadMusic::Content::Flow.new(name: "I") }
    let(:second_movement) { HeadMusic::Content::Flow.new(name: "II") }

    before do
      project.flows.push(first_movement, second_movement)
      first_movement.add_part(player: player)
      second_movement.add_part
    end

    it "finds this player's part in each flow it plays in" do
      expect(player.parts.map(&:flow)).to eq [first_movement]
    end

    it "is empty for a player with no project" do
      expect(described_class.new(name: "Nobody").parts).to be_empty
    end
  end
end
