require "spec_helper"

describe HeadMusic::Analysis::DiatonicInterval::Inversion do
  def inversion_of(name)
    interval = HeadMusic::Analysis::DiatonicInterval.get(name)
    described_class.new(interval.lower_pitch, interval.higher_pitch).interval
  end

  it "turns a third into a sixth" do
    expect(inversion_of("major_third").shorthand).to eq "m6"
  end

  it "turns a fifth into a fourth" do
    expect(inversion_of("perfect_fifth").shorthand).to eq "P4"
  end

  it "turns a diminished interval into an augmented one" do
    expect(inversion_of("diminished_fifth").shorthand).to eq "A4"
  end

  # Musically the inversion of a unison is an octave. The lower pitch only
  # climbs while it is *below* the higher one, and in a unison it already is
  # not, so it stays put. Pinned as it behaves, not as theory would have it.
  it "leaves a unison where it is rather than raising it to an octave" do
    expect(inversion_of("perfect_unison").shorthand).to eq "P1"
  end

  it "raises the lower pitch clear of the higher one" do
    interval = HeadMusic::Analysis::DiatonicInterval.get("major_third")
    expect(described_class.new(interval.lower_pitch, interval.higher_pitch).interval.lower_pitch)
      .to eq interval.higher_pitch
  end
end
