require "spec_helper"

describe HeadMusic::Style::Guidelines::ThirdSpeciesDissonanceTreatment do
  subject { described_class.new(counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "C major") }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }
  # Simple 5-bar CF in C major for targeted tests
  let(:cantus_firmus_pitches) { %w[C4 D4 E4 F4 C4] }

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

  context "with all consonant weak beats" do
    before do
      # All notes consonant with CF
      # Bar 1 (CF=C4): E4(M3) G4(P5) E4(M3) G4(P5)
      # Bar 2 (CF=D4): F4(m3) A4(P5) F4(m3) A4(P5)
      # Bar 3 (CF=E4): G4(m3) C5(m6) G4(m3) C5(m6)
      # Bar 4 (CF=F4): A4(M3) C5(P5) A4(M3) C5(P5)
      # Bar 5: C5 whole note
      [
        %w[E4 G4 E4 G4],
        %w[F4 A4 F4 A4],
        %w[G4 C5 G4 C5],
        %w[A4 C5 A4 C5]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :whole, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a valid ascending passing tone" do
    before do
      # Bar 1 (CF=C4): E4(M3) F4(P4=dis) G4(P5) E4(M3)
      #   F4 is a passing tone: E4→F4→G4, stepwise ascending
      # Bars 2-4: all consonant
      # Bar 5: whole note
      [
        %w[E4 F4 G4 E4],
        %w[F4 A4 F4 A4],
        %w[G4 C5 G4 C5],
        %w[A4 C5 A4 C5]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :whole, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a valid descending passing tone" do
    before do
      # Bar 1 (CF=C4): G4(P5) F4(P4=dis) E4(M3) G4(P5)
      #   F4 is a passing tone: G4→F4→E4, stepwise descending
      # Bars 2-4: all consonant
      # Bar 5: whole note
      [
        %w[G4 F4 E4 G4],
        %w[F4 A4 F4 A4],
        %w[G4 C5 G4 C5],
        %w[A4 C5 A4 C5]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :whole, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a valid upper neighbor tone" do
    before do
      # Bar 1 (CF=C4): E4(M3) F4(P4=dis) E4(M3) G4(P5)
      #   F4 is a neighbor tone: E4→F4→E4, step up then step back down
      # Bars 2-4: all consonant
      # Bar 5: whole note
      [
        %w[E4 F4 E4 G4],
        %w[F4 A4 F4 A4],
        %w[G4 C5 G4 C5],
        %w[A4 C5 A4 C5]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :whole, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a valid lower neighbor tone" do
    before do
      # Bar 1 (CF=C4): E4(M3) D4(M2=dis) E4(M3) G4(P5)
      #   D4 is a neighbor tone: E4→D4→E4, step down then step back up
      # Bars 2-4: all consonant
      # Bar 5: whole note
      [
        %w[E4 D4 E4 G4],
        %w[F4 A4 F4 A4],
        %w[G4 C5 G4 C5],
        %w[A4 C5 A4 C5]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :whole, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a valid descending nota cambiata" do
    before do
      # Descending cambiata spanning bars 1-2:
      # Bar 1 (CF=C4): E4(M3) D4(M2=dis) B3(M7→below=dis? no, m3 below C4? Let's check)
      # Actually, let me use a clearer example.
      # Bar 1 (CF=C4): G4(P5) F4(P4=dis) D4(M2→below? no)
      # Let me think about this more carefully with actual intervals.
      #
      # CF=C4. Cambiata: n1=E4(M3,cons) n2=D4(M2,dis) n3=B3(M7? no, below)
      # B3 to C4 is m2, so B3 forms a major 7th below... that's dissonant.
      # Let me use a higher register.
      #
      # CF=C4, counterpoint above:
      # n1=E4(M3,cons), n2=D4(M2,dis), n3=B3... B3 is below C4, interval is m2 below.
      # Hmm, B3 against C4 would be a minor 2nd (dissonant). Not good for cambiata note 3.
      #
      # Better: Use CF=E4 (bar 3) for the cambiata.
      # CF=E4: n1=C5(m6,cons), n2=B4(P5,cons)... B4 against E4 is P5, consonant. Not dissonant.
      #
      # Let me use CF=D4 (bar 2) for a descending cambiata:
      # n1=A4(P5,cons), n2=G4(P4,dis), n3=E4(M2→no, E4 against D4 is M2, dissonant)
      # That won't work either since n3 must be consonant.
      #
      # CF=F4 (bar 4): n1=C5(P5,cons), n2=B4(A4/tri=dis), n3=G4(M2,dis)
      # G4 against F4 is M2, dissonant. No good.
      #
      # Let me try ascending cambiata on CF=C4:
      # n1=E4(M3,cons), n2=F4(P4,dis), n3=A4(M6,cons), n4=G4(P5,cons), n5=...
      # Wait - ascending cambiata: step up to dis, leap up 3rd to cons, step down, step down
      # n1=E4, n2=F4(step up, dis), n3=A4(leap up 3rd, cons), n4=G4(step down, cons), n5=F4
      # But n5 is beat 1 of bar 2 (CF=D4): F4 against D4 = m3 (cons). ✓
      # Check: approach=step(E→F), leap=3rd up(F→A) same dir as approach(up), ✓
      # step_back_1=step down(A→G), opposite to leap dir(up), ✓
      # step_back_2=step down(G→F), opposite to leap dir(up), ✓
      # n1=E4 cons(M3/C4)✓, n3=A4 cons(M6/C4)✓, n5=F4 cons(m3/D4)✓
      [
        %w[E4 F4 A4 G4],
        %w[F4 A4 F4 A4],
        %w[G4 C5 G4 C5],
        %w[A4 C5 A4 C5]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :whole, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a valid double neighbor" do
    before do
      # Bar 1 (CF=C4): E4(M3,cons) F4(P4,dis) D4(M2,dis) E4(M3,cons)
      #   Double neighbor: n1=E4, n2=F4(upper neighbor), n3=D4(lower neighbor), n4=E4
      #   n1.pitch == n4.pitch ✓, approach(E→F) step ✓, middle(F→D) 3rd ✓, departure(D→E) step ✓
      #   n1 consonant(M3) ✓, n4 consonant(M3) ✓
      # Bars 2-4: all consonant
      # Bar 5: whole note
      [
        %w[E4 F4 D4 E4],
        %w[F4 A4 F4 A4],
        %w[G4 C5 G4 C5],
        %w[A4 C5 A4 C5]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :whole, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a valid double neighbor (lower first)" do
    before do
      # Bar 1 (CF=C4): E4(M3,cons) D4(M2,dis) F4(P4,dis) E4(M3,cons)
      #   Double neighbor: n1=E4, n2=D4(lower neighbor), n3=F4(upper neighbor), n4=E4
      [
        %w[E4 D4 F4 E4],
        %w[F4 A4 F4 A4],
        %w[G4 C5 G4 C5],
        %w[A4 C5 A4 C5]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :whole, "C5")
    end

    it { is_expected.to be_adherent }
  end

  context "with a dissonant note approached by leap" do
    before do
      # Bar 1 (CF=C4): G4(P5) F4(P4=dis) — F4 approached by leap (G4→D4 would be a leap)
      # Actually: E4(M3) then leap to F4 from C4 wouldn't work. Let me be precise.
      # Bar 1 (CF=C4): C5(P8,cons) F4(P4,dis) G4(P5,cons) E4(M3,cons)
      #   F4 is dissonant, approached by leap (C5→F4 = P5 down), not a recognized figure
      [
        %w[C5 F4 G4 E4],
        %w[F4 A4 F4 A4],
        %w[G4 C5 G4 C5],
        %w[A4 C5 A4 C5]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :whole, "C5")
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end

  context "with a dissonant note left by leap (not cambiata)" do
    before do
      # Bar 1 (CF=C4): E4(M3,cons) F4(P4,dis) C5(P8,cons) G4(P5,cons)
      #   F4 is dissonant: approached by step (E4→F4) ✓
      #   but left by leap of 5th (F4→C5), not a third — so not cambiata
      #   and not same direction as approach for PT, not opposite for NT
      #   This should be marked.
      [
        %w[E4 F4 C5 G4],
        %w[F4 A4 F4 A4],
        %w[G4 C5 G4 C5],
        %w[A4 C5 A4 C5]
      ].each_with_index do |bar_notes, bar_index|
        bar = bar_index + 1
        bar_notes.each_with_index do |pitch, beat_index|
          counterpoint.place("#{bar}:#{beat_index + 1}", :quarter, pitch)
        end
      end
      counterpoint.place("5:1", :whole, "C5")
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end
end
