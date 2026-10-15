require "spec_helper"

describe TupletFixtures do
  let(:graced) do
    [
      ["1:3:000", [[%w[A4 C5], "sixteenth", false, false, []]]],
      ["1:4:000", [[%w[G4], "sixteenth", false, false, ["staccato"]]]],
      ["2:1:000", [[%w[F4], "eighth", true, false, []]]],
      ["3:1:000", [[%w[D4], "sixteenth", false, false, []], [%w[C4], "sixteenth", false, true, []]]]
    ]
  end

  it "summarizes each group as from, to, ratio, and unit" do
    expect(tuplet_summary(described_class.triplets)).to eq [[
      ["1:1:000", "1:2:000", "triplet", "eighth"], ["1:2:000", "1:3:000", "triplet", "eighth"], ["1:3:000", "2:1:000", "triplet", "quarter"]
    ]]
  end

  it "summarizes an ungrouped run's brackets as a group's" do
    grouped = described_class.ungrouped_tuplet_run.tap do |flow|
      %w[1:1 1:2].each { |from| flow.voices.first.group_tuplet(from: from, to: flow.position(from).advance(subticks: 230_400)) }
    end
    expect(bracket_summary(described_class.ungrouped_tuplet_run)).to eq bracket_summary(grouped)
  end

  it "summarizes a crossing group's bracket by its exact ends" do
    expect(bracket_summary(described_class.septuplet_crossing_barline)).to eq [[["1+3/4", "2+1/4", "7:4", "eighth"]]]
  end

  it "summarizes grace notes and the slurs from them" do
    expect(grace_summary(described_class.grace_notes_before_downbeat).first)
      .to eq [graced, ["slur from the grace notes before 3:1:000 to 3:1:000"]]
  end

  it "summarizes what sounds by exact onset and length" do
    expect(sounding_summary(described_class.septuplet).first.first(2)).to eq [["1+0", 1/28r, ["C4"]], ["1+1/28", 1/28r, ["D4"]]]
  end

  it "compares flows by these summaries" do
    expect_same_tuplets(described_class.triplets, described_class.triplets)
    expect_same_grace_notes(described_class.grace_notes_in_pickup, described_class.grace_notes_in_pickup)
  end

  it "names the fixtures that cross a barline" do
    expect(described_class.crossing_barline.map { |fixture| bracket_summary(described_class.public_send(fixture)).flatten(1).length }).to eq [1, 1]
  end
end
