require "spec_helper"

describe HeadMusic::Analysis::KeyFinder::KeyPath do
  def path(scores, change_penalty: 1.0, preference: [[0], [1]])
    described_class.new(scores, change_penalty: change_penalty, preference: preference).to_a
  end

  describe "#to_a" do
    it "changes key where the gain outweighs the penalty" do
      expect(path([[2, 0], [0, 3], [0, 3]])).to eq [0, 1, 1]
    end

    it "keeps the key where the gain does not outweigh the penalty" do
      expect(path([[1, 0], [0, 0.5], [1, 0]])).to eq [0, 0, 0]
    end

    it "carries the key through a bar that scores nothing" do
      expect(path([[1, 0], [0, 0], [0, 2]], change_penalty: 0)).to eq [0, 0, 1]
    end

    it "breaks a tie by preference" do
      expect(path([[1, 1]], preference: [[1], [0]])).to eq [1]
    end
  end
end
