require "spec_helper"

describe HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }
  let(:cantus_firmus_pitches) { %w[D4 F4 E4 E4 D4 G4 F4 A4 G4 F4 D4] }

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

  context "with no parallel perfect consonances" do
    before do
      # Fourth species: counterpoint enters on beat 3, ties across barlines.
      # All intervals are imperfect consonances (thirds and sixths).
      # Bar 1: rest beat 1, CP=B4 on beat 3 (M6 above D4)
      # Bar 2: B4 sustains (P4 above F4 — not perfect consonance in two-part),
      #         CP=A4 on beat 3 (M3 above F4... wait, F4 to A4 = M3)
      # Bar 3: A4 sustains (P4 above E4), CP=C5 on beat 3 (m6 above E4)
      # Bar 4: C5 sustains (m6 above E4), CP=B4 on beat 3 (P5 above E4)
      # Bar 5: B4 sustains (M6 above D4), CP=F4 on beat 3 (m3 above D4)
      # Bar 6: F4 sustains (m7 below G4), CP=B4 on beat 3 (M3 above G4)
      # Bar 7: B4 sustains (P4 above F4... skip, keep imperfect)
      # Let me just use clearly imperfect intervals throughout.
      offbeat_pitches = %w[B4 A4 C5 B4 F4 B4 A4 C5 B4 A4]
      offbeat_pitches.each_with_index do |pitch, index|
        bar = index + 1
        counterpoint.place("#{bar}:3", :half, pitch)
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    it { is_expected.to be_adherent }
  end

  context "with parallel fifths across syncopation" do
    let(:cantus_firmus_pitches) { %w[D4 F4 E4 E4 D4 G4 F4 A4 G4 F4 D4] }

    before do
      # Fourth species counterpoint with a parallel fifth violation.
      # CF bars 3 and 4 are both E4 (repeated note).
      # Bar 3 beat 3: CP=B4 (P5 above E4)
      # Bar 4 beat 3: CP=B4 (P5 above E4)
      # With half-note CP, both voices only overlap at CP off-beat positions.
      # Consecutive off-beat intervals at 3:3 and 4:3 are both P5 — parallel fifths!
      offbeat_pitches = %w[B4 A4 B4 B4 F4 B4 A4 C5 B4 A4]
      offbeat_pitches.each_with_index do |pitch, index|
        bar = index + 1
        counterpoint.place("#{bar}:3", :half, pitch)
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with parallel octaves across syncopation" do
    let(:cantus_firmus_pitches) { %w[D4 F4 E4 E4 D4 G4 F4 A4 G4 F4 D4] }

    before do
      # Fourth species counterpoint with a parallel octave violation.
      # CF bars 3 and 4 are both E4 (repeated note).
      # Bar 3 beat 3: CP=E5 (P8 above E4)
      # Bar 4 beat 3: CP=E5 (P8 above E4)
      # Consecutive off-beat intervals at 3:3 and 4:3 are both P8 — parallel octaves!
      offbeat_pitches = %w[B4 A4 E5 E5 F4 B4 A4 C5 B4 A4]
      offbeat_pitches.each_with_index do |pitch, index|
        bar = index + 1
        counterpoint.place("#{bar}:3", :half, pitch)
      end
      counterpoint.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with a fifth followed by an octave (non-parallel)" do
    let(:cantus_firmus_pitches) { %w[D4 G4 D4 E4] }

    before do
      # CP=D5 at bar 1 beat 3: P8 above D4
      # Bar 2 beat 1: D5 sustained, CF=G4: P5 above G4
      # Different perfect consonance types (P8 then P5), so no parallel violation.
      counterpoint.place("1:3", :half, "D5")
      counterpoint.place("2:3", :half, "B4")
      counterpoint.place("3:3", :half, "B4")
      counterpoint.place("4:1", :whole, "B4")
    end

    it { is_expected.to be_adherent }
  end
end
