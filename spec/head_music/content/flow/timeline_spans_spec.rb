require "spec_helper"

describe HeadMusic::Content::Flow::TimelineSpans do
  subject(:spans) { described_class.new("fermata") }

  def position(*args)
    HeadMusic::Time::MusicalPosition.new(*args)
  end

  def fermata(from, to)
    HeadMusic::Time::Fermata.new(from: position(*from), to: position(*to))
  end

  def a_tempo(at)
    HeadMusic::Time::ATempo.new(position: position(*at))
  end

  it "keeps its items in order of their starts" do
    later = spans.add(fermata([3], [4]))
    earlier = spans.add(fermata([1, 2], [1, 3]))
    expect(spans.to_a).to eq [earlier, later]
  end

  it "allows items that touch" do
    spans.add(fermata([1], [2]))
    expect { spans.add(fermata([2], [3])) }.not_to raise_error
  end

  it "refuses an item that overlaps the one before it" do
    spans.add(fermata([1], [2, 2]))
    expect { spans.add(fermata([2], [3])) }
      .to raise_error(ArgumentError, "the fermata from 2:1:0:0 to 3:1:0:0 overlaps the fermata from 1:1:0:0 to 2:2:0:0")
  end

  it "refuses an item that overlaps the one after it" do
    spans.add(fermata([2], [3]))
    expect { spans.add(fermata([1], [2, 2])) }.to raise_error(ArgumentError, /overlaps/)
  end

  it "refuses an item that encloses another" do
    spans.add(fermata([2, 2], [2, 3]))
    expect { spans.add(fermata([2], [3])) }.to raise_error(ArgumentError, /overlaps/)
  end

  it "refuses a second point at the same position" do
    points = described_class.new("a tempo")
    points.add(a_tempo([3]))
    expect { points.add(a_tempo([3])) }.to raise_error(ArgumentError, "the a tempo at 3:1:0:0 overlaps the a tempo at 3:1:0:0")
  end

  it "allows points at different positions" do
    points = described_class.new("a tempo")
    points.add(a_tempo([3]))
    expect { points.add(a_tempo([3, 2])) }.not_to raise_error
  end

  it "describes an item by its noun and ends" do
    expect(spans.describe(fermata([1], [2]))).to eq "fermata from 1:1:0:0 to 2:1:0:0"
  end

  describe "#remove" do
    it "removes and answers the item starting at a position" do
      item = spans.add(fermata([1], [2]))
      expect([spans.remove(position(1)), spans.to_a]).to eq [item, []]
    end

    it "answers nil where none starts" do
      spans.add(fermata([1], [2]))
      expect(spans.remove(position(1, 2))).to be_nil
    end
  end

  describe "#covering" do
    let!(:item) { spans.add(fermata([2], [3])) }

    it "answers the item from its start" do
      expect(spans.covering(position(2))).to eq item
    end

    it "answers the item inside it" do
      expect(spans.covering(position(2, 4, 959))).to eq item
    end

    it "answers nothing at its end" do
      expect(spans.covering(position(3))).to be_nil
    end

    it "answers nothing before it" do
      expect(spans.covering(position(1, 4))).to be_nil
    end

    it "never answers a point" do
      points = described_class.new("a tempo")
      points.add(a_tempo([3]))
      expect(points.covering(position(3))).to be_nil
    end
  end

  describe "#latest_at_or_before" do
    let!(:first) { spans.add(fermata([2], [3])) }
    let!(:second) { spans.add(fermata([5], [6])) }

    it "answers the latest to have begun" do
      expect(spans.latest_at_or_before(position(4))).to eq first
    end

    it "answers one beginning at the position" do
      expect(spans.latest_at_or_before(position(5))).to eq second
    end

    it "answers nil before the first" do
      expect(spans.latest_at_or_before(position(1))).to be_nil
    end
  end
end
