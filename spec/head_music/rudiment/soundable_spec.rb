require "spec_helper"

describe HeadMusic::Rudiment::Soundable do
  it "is the role of a pitch" do
    expect(HeadMusic::Rudiment::Pitch.get("C4")).to be_a described_class
  end

  it "is the role of an unpitched sound" do
    expect(HeadMusic::Rudiment::UnpitchedSound.get("snare drum")).to be_a described_class
  end

  it "requires an includer to say whether it is pitched" do
    soundable = Class.new { include HeadMusic::Rudiment::Soundable }.new
    expect { soundable.pitched? }.to raise_error(NotImplementedError, /must say whether it is pitched/)
  end
end
