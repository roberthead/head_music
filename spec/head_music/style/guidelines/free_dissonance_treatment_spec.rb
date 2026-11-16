require "spec_helper"

describe HeadMusic::Style::Guidelines::FreeDissonanceTreatment do
  let(:flow) do
    HeadMusic::Notation::ABC.parse(<<~ABC)
      X:1
      M:4/4
      L:1/4
      K:C
      V:upper
      #{upper}
      V:lower
      #{lower}
    ABC
  end
  let(:upper_voice) { flow.voices.first }
  let(:lower_voice) { flow.voices.last }

  def marks_in(voice)
    assess(described_class, voice).marks.map(&:code)
  end

  shared_examples "no marks in either voice" do
    it "marks neither voice" do
      expect([marks_in(upper_voice), marks_in(lower_voice)]).to eq [[], []]
    end
  end

  context "with a passing tone on beat 3 against a held note" do
    let(:upper) { "e2 f g|a4|]" }
    let(:lower) { "C4|C4|]" }

    it_behaves_like "no marks in either voice"
  end

  context "with a dissonance leapt to on beat 3 against a held note" do
    let(:upper) { "c'2 f2|e4|]" }
    let(:lower) { "C4|C4|]" }

    it "marks the leaping voice only" do
      expect([marks_in(upper_voice), marks_in(lower_voice)]).to eq [["1:3:000 to 2:1:000"], []]
    end
  end

  context "with a dissonance both voices attack on a downbeat" do
    let(:upper) { "c'4|d'4|c'4|]" }
    let(:lower) { "C4|E4|C4|]" }

    it "marks both voices" do
      expect([marks_in(upper_voice), marks_in(lower_voice)]).to eq [["2:1:000 to 3:1:000"], ["2:1:000 to 3:1:000"]]
    end
  end

  context "with a suspension prepared, held over the barline, and resolved down by step" do
    let(:upper) { "e2 f2-|f2 e2|]" }
    let(:lower) { "A,4|G,2 C2|]" }

    it "lets the held voice own the dissonance, so the moving voice is not marked" do
      expect([marks_in(upper_voice), marks_in(lower_voice)]).to eq [[], []]
    end
  end

  context "with a suspension that resolves upward" do
    let(:upper) { "e2 f2-|f2 g2|]" }
    let(:lower) { "A,4|G,4|]" }

    it "marks the held note and not the voice that moved beneath it" do
      expect([marks_in(upper_voice), marks_in(lower_voice)]).to eq [["1:3:000 to 2:3:000"], []]
    end
  end

  context "with a suspension resolved on the next downbeat, a strong beat late" do
    let(:upper) { "e2 f2-|f2 g2|e4|]" }
    let(:lower) { "A,4|G,4|C4|]" }

    it_behaves_like "no marks in either voice"
  end

  context "with a suspension resolved after the second strong beat" do
    let(:upper) { "e2 f2-|f2 g2|g2 e2|]" }
    let(:lower) { "A,4|G,4|C4|]" }

    it "marks the held note" do
      expect(marks_in(upper_voice)).to include("1:3:000 to 2:3:000")
    end
  end

  context "with a suspension struck again, prepared and resolved down by step" do
    let(:upper) { "e2 f2|f2 e2|]" }
    let(:lower) { "A,4|G,2 C2|]" }

    it_behaves_like "no marks in either voice"
  end

  context "with a suspension struck again and never resolved" do
    let(:upper) { "e2 f2|f2 g2|]" }
    let(:lower) { "A,4|G,4|]" }

    it "marks the struck note and not the voice that moved beneath it" do
      expect([marks_in(upper_voice), marks_in(lower_voice)]).to eq [["2:1:000 to 2:3:000"], []]
    end
  end

  context "with a note struck again from a dissonance" do
    let(:upper) { "e2 f2|f2 e2|]" }
    let(:lower) { "G,4|G,2 C2|]" }

    it "marks the unprepared suspension" do
      expect(marks_in(upper_voice)).to include("2:1:000 to 2:3:000")
    end
  end

  # Salzer & Schachter list "dissonant passing tones in both species parts"
  # among the basic situations of combined species (p. 330).
  context "with dissonant passing tones attacked together in both voices" do
    let(:upper) { "c' a g f|g4|]" }
    let(:lower) { "C2 D2|E4|]" }

    it_behaves_like "no marks in either voice"
  end

  context "with a leap into a chord tone against a passing tone in the other voice" do
    let(:upper) { "c' a g f|g4|]" }
    let(:lower) { "C2 A,2|C4|]" }

    it_behaves_like "no marks in either voice"
  end

  context "with a simultaneous dissonance neither voice explains" do
    let(:upper) { "c'2 f2|e4|]" }
    let(:lower) { "C2 G,2|C4|]" }

    it "marks both voices" do
      expect([marks_in(upper_voice), marks_in(lower_voice)]).to eq [["1:3:000 to 2:1:000"], ["1:3:000 to 2:1:000"]]
    end
  end

  context "with two dissonant passing tones in a row between consonances" do
    let(:upper) { "g f e d|c4|]" }
    let(:lower) { "B,4|C4|]" }

    it_behaves_like "no marks in either voice"
  end

  # Each line steps through the sevenths in one direction, so shape alone
  # would call every note a passing tone. Neither run begins on a consonance.
  context "with parallel sevenths stepping through the weak beats" do
    let(:upper) { "e' b c' d'|g4|]" }
    let(:lower) { "C C D E|C4|]" }

    it "marks the sevenths in both voices" do
      expect(marks_in(upper_voice)).to include("1:3:000 to 1:4:000")
      expect(marks_in(lower_voice)).to include("1:3:000 to 1:4:000")
    end
  end

  context "with a dissonance entered after a rest, stepping on to a consonance" do
    let(:upper) { "c z d e|c4|]" }
    let(:lower) { "C4|C4|]" }

    it "marks the dissonance, since the rest breaks the passing figure" do
      expect(marks_in(upper_voice)).to eq ["1:3:000 to 1:4:000"]
    end
  end

  context "with a downbeat suspension decorated before resolving on beat 3 while the other voice moves" do
    let(:upper) { "e2 g2-|g a f2|e4|]" }
    let(:lower) { "C4|A,2 D2|C4|]" }

    it_behaves_like "no marks in either voice"
  end

  context "with a suspension over beat 3 resolving on the next downbeat" do
    let(:upper) { "e g2 a|f4|]" }
    let(:lower) { "C2 F2|D4|]" }

    it_behaves_like "no marks in either voice"
  end

  context "with a resolution dissonant with the voice that moved beneath it" do
    let(:upper) { "e2 g2-|g a f2|e4|]" }
    let(:lower) { "C4|A,2 E2|C4|]" }

    it "marks the suspension" do
      expect(marks_in(upper_voice)).to include("1:3:000 to 2:2:000")
    end
  end

  context "with a dissonant eighth after a dotted quarter" do
    let(:lower) { "C4|G,4|]" }

    context "when it passes" do
      let(:upper) { "c'3/2 b/ a2|b4|]" }

      it_behaves_like "no marks in either voice"
    end

    # A cambiata elsewhere, but the eighth after a dotted quarter takes only a
    # passing or neighbor tone.
    context "when it begins a cambiata" do
      let(:upper) { "c'3/2 b/ g a|b4|]" }

      it "marks the eighth" do
        expect(marks_in(upper_voice).length).to eq 1
      end
    end
  end

  context "with a cambiata on quarters" do
    let(:upper) { "c' b g a|b4|]" }
    let(:lower) { "C4|G,4|]" }

    it_behaves_like "no marks in either voice"
  end

  context "with no other voice" do
    let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nc d e f|]\n") }

    it "marks nothing" do
      expect(marks_in(flow.voices.first)).to be_empty
    end
  end
end
