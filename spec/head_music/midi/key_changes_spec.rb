require "spec_helper"

describe HeadMusic::MIDI::KeyChanges do
  let(:layout) { HeadMusic::MIDI::BarLayout.new([], division: 96, end_tick: 96 * 4 * 3) }
  let(:onsets) { HeadMusic::MIDI::Onsets.new([0r, 1r, 9/4r]) }

  def regions(*signatures)
    timed = signatures.map { |time, fifths, minor| [time, HeadMusic::MIDI::KeySignature.new(0, fifths, minor)] }
    described_class.new(timed, layout, onsets).regions.map { |region| [region.bar_number, region.key.name] }
  end

  it "reads nothing from a file with no key signatures" do
    expect(regions).to eq []
  end

  it "opens in C major before a first signature after the first bar" do
    expect(regions([1r, 1, false])).to eq [[1, "C major"], [2, "G major"]]
  end

  it "keeps only the signatures that differ from the one before" do
    expect(regions([0r, -3, true], [1r, -3, true], [2r, 2, false])).to eq [[1, "C minor"], [3, "D major"]]
  end

  it "applies a signature within a bar at the next downbeat when a note starts before it there" do
    expect(regions([0r, 0, false], [5/4r, 1, false]).map(&:first)).to eq [1, 3]
  end

  it "applies a signature within a bar at its downbeat when no note starts before it there" do
    expect(regions([0r, 0, false], [17/8r, 1, false])).to eq [[1, "C major"], [3, "G major"]]
  end
end
