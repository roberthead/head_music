require "spec_helper"

describe HeadMusic::Notation::ChordClashes do
  def among(*names)
    described_class.among(names.map { |name| HeadMusic::Rudiment::Pitch.get(name) }).map(&:to_s)
  end

  it "finds members at one letter and octave under different alterations" do
    expect(among("F4", "A4", "F#4", "Bb4", "B4")).to eq ["F4", "F♯4", "B♭4", "B4"]
  end

  it "finds nothing in other octaves, under other letters, or in a doubled pitch" do
    expect(among("F4", "F#5", "Gb4", "C4", "C4")).to be_empty
  end
end
