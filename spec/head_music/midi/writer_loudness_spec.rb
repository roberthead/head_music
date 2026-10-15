require "spec_helper"

describe HeadMusic::MIDI::Writer do
  subject(:sequence) { render_midi(flow) }

  def abc(body, meter: "4/4")
    HeadMusic::Notation::ABC.parse("X:1\nT:Loudness\nM:#{meter}\nL:1/4\nK:C\n#{body}\n")
  end

  def velocities
    sequence.notes.map(&:velocity)
  end

  context "with no level written" do
    let(:flow) { abc("C D E F|") }

    it "strikes every note at mf" do
      expect(velocities).to eq [80, 80, 80, 80]
    end
  end

  context "with levels" do
    let(:flow) { abc("!pp!C D !f!E F|") }

    it "strikes each note at the level in force at its onset" do
      expect(velocities).to eq [32, 32, 96, 96]
    end
  end

  context "with a chord" do
    let(:flow) { abc("!p!!accent![CEG]4|") }

    it "strikes every pitch at one velocity" do
      expect(velocities).to eq [64, 64, 64]
    end
  end

  context "with an fp note" do
    let(:flow) { abc("!mf!C !fp!D E F|") }

    it "strikes it at f and the notes after it at p" do
      expect(velocities).to eq [80, 96, 48, 48]
    end
  end

  context "with an sfz and an accent on one note" do
    let(:flow) { abc("!p!C !sfz!!accent!D E !marcato!F|") }

    it "adds both boosts" do
      expect(velocities).to eq [48, 88, 48, 72]
    end
  end

  context "with boosts past the loudest velocity" do
    let(:flow) { abc("!fff!!sfz!!marcato!C4|") }

    it "clamps to 127" do
      expect(velocities).to eq [127]
    end
  end

  context "with a crescendo to a level" do
    let(:flow) { abc("!p!!<(!C D E F|!<)!!f!G4|") }

    it "interpolates each note's velocity by its onset" do
      expect(velocities).to eq [48, 60, 72, 84, 96]
    end
  end

  context "with a crescendo to no level" do
    let(:flow) { abc("!p!!<(!C D E F|!<)!G2 G2|!pp!C4|") }

    it "ramps one level up and holds it until the next level" do
      expect(velocities).to eq [48, 52, 56, 60, 64, 64, 32]
    end
  end

  context "with a crescendo inside a repeat" do
    let(:flow) { abc("|:!p!!<(!C D E F|!<)!!f!G4:|") }

    it "plays the same ramp on every pass" do
      expect(velocities).to eq [48, 60, 72, 84, 96] * 2
    end
  end

  context "with a part's hairpins over two voices and a voice's own" do
    let(:flow) { MuseScoreFixtures.piano_part_marks }

    def velocities_of(key)
      sequence.notes.select { |note| note.key == key }.map(&:velocity)
    end

    it "ramps the right hand, whose own mf ends the part's diminuendo's first piece" do
      expect(velocities_of(76)).to eq [48, 80, 80, 64]
    end

    it "ramps the left hand from the part's own levels" do
      expect(velocities_of(48)).to eq [48, 80, 96, 64]
    end
  end
end
