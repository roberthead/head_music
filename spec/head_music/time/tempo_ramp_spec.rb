require "spec_helper"

describe HeadMusic::Time::TempoRamp do
  let(:from) { HeadMusic::Time::MusicalPosition.new(12) }
  let(:to) { HeadMusic::Time::MusicalPosition.new(13) }
  let(:allegro) { HeadMusic::Rudiment::Tempo.new("quarter", 120, text: "Allegro") }

  it "keeps its ends, target, and text" do
    ramp = described_class.new(from: from, to: to, to_tempo: allegro, text: "rit.")
    expect(ramp).to have_attributes(from: from, to: to, to_tempo: allegro, text: "rit.")
  end

  it "needs no target or text" do
    expect(described_class.new(from: from, to: to)).to have_attributes(to_tempo: nil, text: nil)
  end

  it "raises when it does not end after it begins" do
    expect { described_class.new(from: to, to: from) }.to raise_error(ArgumentError, /ends after it begins/)
  end

  it "raises when it ends where it begins" do
    expect { described_class.new(from: from, to: from) }.to raise_error(ArgumentError)
  end

  it "raises for a target of no beats per minute" do
    expect { described_class.new(from: from, to: to, to_tempo: HeadMusic::Rudiment::Tempo.new("quarter", 0)) }
      .to raise_error(ArgumentError, /faster than zero/)
  end

  describe "#default_target" do
    it "slows to three quarters of the start" do
      target = described_class.new(from: from, to: to, text: "rit.").default_target(allegro)
      expect(target).to eq HeadMusic::Rudiment::Tempo.new("quarter", 90, metronome_mark: false)
    end

    it "slows when it has no text" do
      expect(described_class.new(from: from, to: to).default_target(allegro).beats_per_minute).to eq 90
    end

    %w[accel. Accelerando stringendo].each do |text|
      it "speeds up to four thirds of the start for #{text}" do
        target = described_class.new(from: from, to: to, text: text).default_target(allegro)
        expect(target.beats_per_minute).to eq 160
      end
    end

    it "keeps the starting beat value" do
      start = HeadMusic::Rudiment::Tempo.new("dotted quarter", 80)
      expect(described_class.new(from: from, to: to).default_target(start).beat_value.to_s).to eq "dotted quarter"
    end
  end
end
