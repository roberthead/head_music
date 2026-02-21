require "spec_helper"

describe HeadMusic::Style::Guidelines::TripleMeterDissonanceTreatment do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "C major", meter: "3/4") }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }
  # Simple 5-bar CF in C major for targeted tests
  let(:cantus_firmus_pitches) { %w[C4 D4 E4 F4 C4] }

  before do
    composition.add_voice(role: :cantus_firmus).tap do |voice|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :dotted_half, pitch)
      end
    end
  end

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "with all consonant weak beats" do
    before do
      # All notes consonant with CF
      # Bar 1 (CF=C4): E4(M3) G4(P5) E4(M3)
      # Bar 2 (CF=D4): F4(m3) A4(P5) F4(m3)
      # Bar 3 (CF=E4): G4(m3) C5(m6) G4(m3)
      # Bar 4 (CF=F4): A4(M3) C5(P5) A4(M3)
      # Bar 5: C5 dotted half note
      [
        %w[E4 G4 E4],
        %w[F4 A4 F4],
        %w[G4 C5 G4],
        %w[A4 C5 A4]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :dotted_half, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a valid ascending passing tone" do
    before do
      # Bar 1 (CF=C4): E4(M3) F4(P4=dis) G4(P5)
      #   F4 is a passing tone: E4->F4->G4, stepwise ascending
      # Bars 2-4: all consonant
      # Bar 5: dotted half note
      [
        %w[E4 F4 G4],
        %w[F4 A4 F4],
        %w[G4 C5 G4],
        %w[A4 C5 A4]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :dotted_half, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a valid upper neighbor tone" do
    before do
      # Bar 1 (CF=C4): E4(M3) F4(P4=dis) E4(M3)
      #   F4 is a neighbor tone: E4->F4->E4, step up then step back down
      # Bars 2-4: all consonant
      # Bar 5: dotted half note
      [
        %w[E4 F4 E4],
        %w[F4 A4 F4],
        %w[G4 C5 G4],
        %w[A4 C5 A4]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :dotted_half, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a valid lower neighbor tone" do
    before do
      # Bar 1 (CF=C4): E4(M3) D4(M2=dis) E4(M3)
      #   D4 is a neighbor tone: E4->D4->E4, step down then step back up
      # Bars 2-4: all consonant
      # Bar 5: dotted half note
      [
        %w[E4 D4 E4],
        %w[F4 A4 F4],
        %w[G4 C5 G4],
        %w[A4 C5 A4]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :dotted_half, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a dissonant note approached by leap" do
    before do
      # Bar 1 (CF=C4): C5(P8,cons) F4(P4,dis) G4(P5,cons)
      #   F4 is dissonant, approached by leap (C5->F4 = P5 down), not a recognized figure
      [
        %w[C5 F4 G4],
        %w[F4 A4 F4],
        %w[G4 C5 G4],
        %w[A4 C5 A4]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :dotted_half, "C5")
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end
end
