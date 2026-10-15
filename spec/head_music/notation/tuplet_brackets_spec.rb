require "spec_helper"

describe HeadMusic::Notation::TupletBrackets do
  subject(:brackets) { described_class.for(voice) }

  let(:flow) { HeadMusic::Content::Flow.new }
  let(:voice) { flow.add_voice }
  let(:triplet_eighth) { HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "3:2") }

  def place_in_turn(*values)
    values.each { |value| voice.place(voice.next_position, value, "C4") }
  end

  def summary(brackets)
    brackets.map { |bracket| [bracket.label, bracket.unit.to_s, bracket.links.map { |link| [link.bar_number, link.rhythmic_value.to_s] }] }
  end

  it "brackets a group" do
    place_in_turn(*Array.new(3, triplet_eighth), :half, :quarter)
    voice.group_tuplet(from: "1:1", to: "1:2")
    expect(summary(brackets)).to eq [["3:2 tuplet from 1:1:000 to 1:2:000", "eighth", Array.new(3, [1, "triplet eighth"])]]
  end

  it "answers the group it brackets" do
    place_in_turn(*Array.new(3, triplet_eighth), "dotted half")
    expect(brackets.first&.group).to be_nil
  end

  it "brackets an ungrouped run as a writer counts it, by threes of its shortest unit" do
    place_in_turn(*Array.new(6, triplet_eighth), :half)
    expect(summary(brackets).map(&:first)).to eq ["3:2 tuplet at 1:1:000", "3:2 tuplet at 1:2:000"]
  end

  it "brackets an ungrouped quarter and eighth under 3:2 together" do
    place_in_turn(HeadMusic::Rudiment::RhythmicValue.get(:quarter, tuplet: "3:2"), triplet_eighth, "dotted half")
    expect(summary(brackets)).to eq [["3:2 tuplet at 1:1:000", "eighth", [[1, "triplet quarter"], [1, "triplet eighth"]]]]
  end

  it "brackets what is left of a run on its own" do
    place_in_turn(*Array.new(4, triplet_eighth), :half)
    expect(brackets.map { |bracket| bracket.links.length }).to eq [3, 1]
  end

  it "keeps runs apart where a group of the same ratio comes between them" do
    place_in_turn(*Array.new(9, triplet_eighth), :quarter)
    voice.group_tuplet(from: "1:2", to: "1:3")
    expect(summary(brackets).map(&:first)).to eq ["3:2 tuplet at 1:1:000", "3:2 tuplet from 1:2:000 to 1:3:000", "3:2 tuplet at 1:3:000"]
  end

  it "leaves a value without a ratio out of every bracket" do
    place_in_turn(triplet_eighth, triplet_eighth, HeadMusic::Rudiment::RhythmicValue.get("triplet eighth tied to quarter"), :half)
    voice.group_tuplet(from: "1:1", to: "1:2")
    expect(brackets.map { |bracket| bracket.links.map(&:index) }).to eq [[0, 0, 0]]
  end

  context "with a group across a barline" do
    before do
      voice.place("1:1", "dotted half", "C4")
      place_in_turn(*Array.new(3, HeadMusic::Rudiment::RhythmicValue.get(:quarter, tuplet: "3:2")), "dotted half")
      voice.group_tuplet(from: "1:4", to: "2:2")
    end

    it "holds the pieces on both sides of the barline" do
      expect(summary(brackets).first.last).to eq [[1, "triplet quarter"], [1, "triplet eighth"], [2, "triplet eighth"], [2, "triplet quarter"]]
    end

    it "crosses the barline" do
      expect([brackets.first.crosses_barline?, brackets.first.bar_numbers]).to eq [true, [1, 2]]
    end

    it "brackets the segments it is given" do
      segments = HeadMusic::Notation::BarSplitter.segments(voice.voice_events)
      expect(described_class.for(voice, segments).first.links.map(&:segment)).to eq segments[1..4]
    end
  end

  it "places a group's links by exact onset despite rounded positions" do
    place_in_turn(*Array.new(14, HeadMusic::Rudiment::RhythmicValue.get(:sixteenth, tuplet: "7:4")), :half)
    voice.group_tuplet(from: "1:1", to: "1:2")
    voice.group_tuplet(from: "1:2", to: "1:3")
    expect([brackets.map { |bracket| bracket.links.length }, brackets.map(&:crosses_barline?)]).to eq [[7, 7], [false, false]]
  end

  it "does not cross a barline within a bar" do
    place_in_turn(*Array.new(3, triplet_eighth), "dotted half")
    expect(brackets.first.crosses_barline?).to be false
  end
end
