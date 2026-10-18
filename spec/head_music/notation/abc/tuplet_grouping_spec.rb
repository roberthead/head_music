require "spec_helper"

describe HeadMusic::Notation::ABC::TupletGrouping do
  subject(:grouping) { described_class.new(voice) }

  let(:voice) { HeadMusic::Content::Flow.new.add_voice(role: nil) }
  let(:triplet) { HeadMusic::Notation::ABC::TupletMarker.for([3], compound: false) }
  let(:pitch) { HeadMusic::Rudiment::Pitch.get("C4") }

  def place_eighth
    ratio, ends = grouping.count
    rhythmic_value = HeadMusic::Notation::ABC::DurationResolver.new("1/8").rhythmic_value("1", tuplet: ratio)
    voice_event = voice.place(voice.next_position, rhythmic_value, [pitch])
    grouping.place_ends(voice_event, ends)
  end

  it "counts nothing while no tuplet is open" do
    expect(grouping.count).to eq [nil, []]
  end

  it "groups a tuplet once its notes are placed" do
    grouping.open(triplet, 1)
    3.times { place_eighth }
    expect(voice.tuplets.map(&:to_s)).to eq ["3:2 tuplet from 1:1:000 to 1:2:000"]
  end

  it "gives the ratio only to the notes the marker counts" do
    grouping.open(triplet, 1)
    ratios = Array.new(4) { grouping.count.first }
    expect(ratios.map(&:nil?)).to eq [false, false, false, true]
  end

  it "leaves a tuplet still owed notes ungrouped when closed" do
    grouping.open(triplet, 1)
    2.times { place_eighth }
    grouping.close
    expect(voice.tuplets).to be_empty
  end

  it "fixes a pending note's open ends at the links counted so far" do
    grouping.open(triplet, 1)
    _, ends = grouping.count
    chain = HeadMusic::Rudiment::RhythmicValue.new(:eighth)
    expect(grouping.fix_ends(ends, nil, chain).map(&:last)).to eq [0]
  end

  it "refuses a tuplet inside a tuplet" do
    grouping.open(triplet, 1)
    expect { grouping.open(triplet, 2) }.to raise_error(HeadMusic::Notation::ABC::UnsupportedFeatureError, /nested tuplets/)
  end
end
