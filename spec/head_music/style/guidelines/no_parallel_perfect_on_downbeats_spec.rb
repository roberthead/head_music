require "spec_helper"

describe HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }
  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }

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

  context "with no parallel perfect consonances on downbeats" do
    before do
      # Downbeat intervals: M6, M3, P5, P5, P5, M3, P5, P5, M3, P5, P8
      # P5 appears on bars 3,4,5 and 7,8 — but bars 3,4 is P5→P5 (parallel!)
      # Actually let me use imperfect consonances to avoid parallels
      # Bar 1: B4(M6/D4), Bar 2: A4(M3/F4), Bar 3: C5(m6/E4),
      # Bar 4: B4(M6/D4), Bar 5: B4(M3/G4), Bar 6: A4(M3/F4),
      # Bar 7: C5(m3/A4), Bar 8: B4(M3/G4), Bar 9: A4(M3/F4),
      # Bar 10: C5(m6/E4), Bar 11: D5(P8/D4)
      downbeat_pitches = %w[B4 A4 C5 B4 B4 A4 C5 B4 A4 C5 D5]
      downbeat_pitches.each_with_index do |pitch, index|
        bar = index + 1
        if bar == 11
          counterpoint.place("#{bar}:1", :whole, pitch)
        else
          counterpoint.place("#{bar}:1", :half, pitch)
          counterpoint.place("#{bar}:3", :half, pitch) # same pitch for simplicity
        end
      end
    end

    it { is_expected.to be_adherent }
  end

  context "with parallel fifths on consecutive downbeats" do
    before do
      # CF bars 1-2: D4 F4
      # Counterpoint: A4(P5/D4) on bar 1, C5(P5/F4) on bar 2 — parallel fifths!
      downbeat_pitches = %w[A4 C5 C5 B4 B4 A4 C5 B4 A4 C5 D5]
      downbeat_pitches.each_with_index do |pitch, index|
        bar = index + 1
        if bar == 11
          counterpoint.place("#{bar}:1", :whole, pitch)
        else
          counterpoint.place("#{bar}:1", :half, pitch)
          counterpoint.place("#{bar}:3", :half, pitch)
        end
      end
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with parallel octaves on consecutive downbeats" do
    before do
      # CF bars 1-2: D4 F4
      # Counterpoint: D5(P8/D4) on bar 1, F5(P8/F4) on bar 2 — parallel octaves!
      downbeat_pitches = %w[D5 F5 C5 B4 B4 A4 C5 B4 A4 C5 D5]
      downbeat_pitches.each_with_index do |pitch, index|
        bar = index + 1
        if bar == 11
          counterpoint.place("#{bar}:1", :whole, pitch)
        else
          counterpoint.place("#{bar}:1", :half, pitch)
          counterpoint.place("#{bar}:3", :half, pitch)
        end
      end
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context "with a fifth followed by an octave on consecutive downbeats" do
    before do
      # CF bars 1-2: D4 F4
      # Counterpoint: A4(P5/D4) on bar 1, F5(P8/F4) on bar 2 — different perfect consonances, OK
      downbeat_pitches = %w[A4 F5 C5 B4 B4 A4 C5 B4 A4 C5 D5]
      downbeat_pitches.each_with_index do |pitch, index|
        bar = index + 1
        if bar == 11
          counterpoint.place("#{bar}:1", :whole, pitch)
        else
          counterpoint.place("#{bar}:1", :half, pitch)
          counterpoint.place("#{bar}:3", :half, pitch)
        end
      end
    end

    it { is_expected.to be_adherent }
  end
end
