require "spec_helper"

describe HeadMusic::MIDI::ChangeCursor do
  subject(:cursor) { described_class.new(changes, &:first) }

  let(:changes) { [[0, :a], [4, :b], [4, :c], [8, :d]] }

  describe "#at" do
    it "answers nil before the first change" do
      expect(described_class.new([[2, :a]], &:first).at(1)).to be_nil
    end

    it "answers the latest change at or before each ascending point" do
      expect([0, 3, 4, 7, 9].map { |point| cursor.at(point)&.last }).to eq %i[a a c c d]
    end

    it "answers nil for no changes" do
      expect(described_class.new([], &:first).at(5)).to be_nil
    end
  end

  describe ".changes" do
    it "keeps each pair whose value differs from the one before" do
      expect(described_class.changes([[1, :a], [2, :a], [3, :b], [4, :a], [5, :a]])).to eq [[1, :a], [3, :b], [4, :a]]
    end

    it "answers nothing for no pairs" do
      expect(described_class.changes([])).to eq []
    end
  end

  describe "#advance" do
    it "answers only the changes reached since the last call" do
      expect([3, 4, 4, 10].map { |point| cursor.advance(point).map(&:last) }).to eq [%i[a], %i[b c], [], %i[d]]
    end
  end
end
