require "spec_helper"

describe HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }
  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4] }

  before do
    composition.add_voice(role: :cantus_firmus).tap do |voice|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end
  end

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "with no parallel perfect consonances across barlines" do
    before do
      # All imperfect consonances on weak beats and following downbeats
      # Bar 1: B4(M6/D4) B4(M6/D4) — weak beat M6
      # Bar 2: A4(M3/F4) — downbeat M3 — M6→M3, OK
      # Bar 2: A4(M3/F4) — weak beat M3
      # Bar 3: C5(m6/E4) — downbeat m6 — M3→m6, OK
      counterpoint.place("1:1", :half, "B4")
      counterpoint.place("1:3", :half, "B4")
      counterpoint.place("2:1", :half, "A4")
      counterpoint.place("2:3", :half, "A4")
      counterpoint.place("3:1", :half, "C5")
      counterpoint.place("3:3", :half, "C5")
      counterpoint.place("4:1", :whole, "A4")
    end

    it { is_expected.to be_adherent }
  end

  context "with parallel fifths from weak beat to next downbeat" do
    before do
      # Bar 1: B4(M6/D4) A4(P5/D4) — weak beat P5
      # Bar 2: C5(P5/F4) — downbeat P5 — parallel fifths across barline!
      counterpoint.place("1:1", :half, "B4")
      counterpoint.place("1:3", :half, "A4")
      counterpoint.place("2:1", :half, "C5")
      counterpoint.place("2:3", :half, "A4")
      counterpoint.place("3:1", :half, "B4")
      counterpoint.place("3:3", :half, "C5")
      counterpoint.place("4:1", :whole, "A4")
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end

  context "with parallel octaves from weak beat to next downbeat" do
    before do
      # Bar 1: B4(M6/D4) D5(P8/D4) — weak beat P8
      # Bar 2: F5(P8/F4) — downbeat P8 — parallel octaves across barline!
      counterpoint.place("1:1", :half, "B4")
      counterpoint.place("1:3", :half, "D5")
      counterpoint.place("2:1", :half, "F5")
      counterpoint.place("2:3", :half, "A4")
      counterpoint.place("3:1", :half, "B4")
      counterpoint.place("3:3", :half, "C5")
      counterpoint.place("4:1", :whole, "A4")
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end

  context "with a fifth on weak beat followed by an octave on next downbeat" do
    before do
      # Bar 1: B4(M6/D4) A4(P5/D4) — weak beat P5
      # Bar 2: F5(P8/F4) — downbeat P8 — different perfect consonances, OK
      counterpoint.place("1:1", :half, "B4")
      counterpoint.place("1:3", :half, "A4")
      counterpoint.place("2:1", :half, "F5")
      counterpoint.place("2:3", :half, "A4")
      counterpoint.place("3:1", :half, "B4")
      counterpoint.place("3:3", :half, "C5")
      counterpoint.place("4:1", :whole, "A4")
    end

    it { is_expected.to be_adherent }
  end
end
