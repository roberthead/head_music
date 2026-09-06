require "spec_helper"

describe HeadMusic::Time::EventMap do
  subject(:map) { described_class.new }

  def position(bar, count = 1, tick = 0, subtick = 0)
    HeadMusic::Time::MusicalPosition.new(bar, count, tick, subtick)
  end

  describe "an empty map" do
    it "is empty" do
      expect(map).to be_empty
    end

    it "answers its default" do
      expect(described_class.new(default: "4/4").at(position(9))).to eq "4/4"
    end

    it "answers nil when it has no default" do
      expect(map.at(position(9))).to be_nil
    end
  end

  describe "#add" do
    it "keeps events in position order however they arrive" do
      map.add(position(9), "9")
      map.add(position(3), "3")
      map.add(position(5), "5")
      expect(map.values).to eq %w[3 5 9]
    end

    it "orders within a bar by count, tick, and subtick" do
      map.add(position(1, 2, 0, 0), "b")
      map.add(position(1, 1, 480, 120), "a")
      map.add(position(1, 3, 0, 0), "c")
      expect(map.values).to eq %w[a b c]
    end

    it "replaces the event already at a position" do
      map.add(position(5), "first")
      map.add(position(5), "second")
      expect(map.values).to eq ["second"]
    end

    it "returns the event it stored" do
      expect(map.add(position(5), "3/4").value).to eq "3/4"
    end
  end

  describe "#at" do
    before do
      map.add(position(1), "a")
      map.add(position(5), "b")
      map.add(position(9), "c")
    end

    it "answers the value in force between events" do
      expect(map.at(position(7))).to eq "b"
    end

    it "answers the value of an event landed on exactly" do
      expect(map.at(position(5))).to eq "b"
    end

    it "answers the last value past the final event" do
      expect(map.at(position(100))).to eq "c"
    end

    it "answers the default before the first event" do
      expect(described_class.new(default: "seed").tap { |m| m.add(position(5), "b") }.at(position(2))).to eq "seed"
    end
  end

  describe "#change_at" do
    before { map.add(position(5), "b") }

    it "finds an event starting exactly at the position" do
      expect(map.change_at(position(5)).value).to eq "b"
    end

    it "finds nothing where a value is merely in force" do
      expect(map.change_at(position(7))).to be_nil
    end
  end

  describe "#remove" do
    before do
      map.add(position(1), "a")
      map.add(position(5), "b")
    end

    it "removes the event at a position" do
      map.remove(position(5))
      expect(map.values).to eq ["a"]
    end

    it "does nothing where there is no event" do
      expect(map.remove(position(7))).to be_nil
    end

    context "when the first event is not removable" do
      subject(:map) { described_class.new(removable_first_event: false) }

      it "refuses to remove it" do
        map.remove(position(1))
        expect(map.values).to eq %w[a b]
      end

      it "still removes a later event" do
        map.remove(position(5))
        expect(map.values).to eq ["a"]
      end
    end
  end

  describe "#clear" do
    before do
      map.add(position(1), "a")
      map.add(position(5), "b")
    end

    it "empties the map" do
      expect(map.clear).to be_empty
    end

    context "when the first event is not removable" do
      subject(:map) { described_class.new(removable_first_event: false) }

      it "keeps the opening event" do
        expect(map.clear.values).to eq ["a"]
      end
    end
  end

  describe "#each_segment" do
    before do
      map.add(position(1), "a")
      map.add(position(5), "b")
      map.add(position(9), "c")
    end

    it "yields one span per value in force over the range" do
      segments = []
      map.each_segment(position(1), position(13)) { |from, to, value| segments << [from.bar, to.bar, value] }
      expect(segments).to eq [[1, 5, "a"], [5, 9, "b"], [9, 13, "c"]]
    end

    it "yields a single span when no event falls inside the range" do
      segments = []
      map.each_segment(position(5), position(7)) { |from, to, value| segments << [from.bar, to.bar, value] }
      expect(segments).to eq [[5, 7, "b"]]
    end

    it "starts from the value in force at the range's opening" do
      segments = []
      map.each_segment(position(6), position(11)) { |from, to, value| segments << [from.bar, to.bar, value] }
      expect(segments).to eq [[6, 9, "b"], [9, 11, "c"]]
    end
  end

  describe "an event" do
    it "describes itself by position and value" do
      expect(map.add(position(5), "3/4").to_s).to eq "5:1:0:0=3/4"
    end
  end
end
