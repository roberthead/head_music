# Where the dissonance guidelines recognize a double neighbor and a nota
# cambiata: the first only from a downbeat, the second only from an accented
# beat (Salzer and Schachter, Counterpoint in Composition, pp. 62-63).
#
# The figure is in the upper voice over held notes. Beside each refused line
# are the intervals its marked notes make with the lower voice.
RSpec.shared_examples "dissonance figure placement" do
  def placement_marks(upper, lower, meter: "4/4")
    flow = HeadMusic::Notation::ABC.parse("X:1\nM:#{meter}\nL:1/4\nK:C\nV:upper\n#{upper}\nV:lower\n#{lower}\n")
    assess(described_class, flow.voices.first).marks.map(&:code)
  end

  describe "a double neighbor" do
    it "is recognized from the downbeat with both neighbors dissonant" do
      expect(placement_marks("e f d e|c4|]", "C4|C4|]")).to eq []
    end

    it "is recognized from the downbeat with one neighbor dissonant" do
      expect(placement_marks("a b g a|g4|]", "C4|C4|]")).to eq []
    end

    # F is a fourth and D a ninth over C.
    it "is refused from beat 2, marking both dissonant neighbors" do
      expect(placement_marks("g e f d|e4|]", "C4|C4|]")).to eq ["1:3:000 to 1:4:000", "1:4:000 to 2:1:000"]
    end

    # A is a sixth and F a fourth over C.
    it "is refused from beat 2, marking the one dissonant neighbor" do
      expect(placement_marks("c' g a f|g4|]", "C4|C4|]")).to eq ["1:4:000 to 2:1:000"]
    end

    # F is a fourth over C, and A on the downbeat a sixth.
    it "is refused from beat 3, marking the neighbor before the barline" do
      expect(placement_marks("e e g f|a g e2|]", "C4|C4|]")).to eq ["1:4:000 to 2:1:000"]
    end

    # A on the downbeat is a sixth over C, and F a fourth.
    it "is refused from beat 4, marking the neighbor after the downbeat" do
      expect(placement_marks("e e e g|a f g2|]", "C4|C4|]")).to eq ["2:2:000 to 2:3:000"]
    end

    # The neighbors follow the downbeat, but the half note carries the return
    # into the next bar.
    it "is refused where it returns in the next bar" do
      expect(placement_marks("e f d2|e4|]", "C4|C4|]")).to eq ["1:2:000 to 1:3:000", "1:3:000 to 2:1:000"]
    end

    # The neighbors fall on beats 3 and 4 after a half-note main tone.
    it "is refused where a long first note carries the neighbors off the downbeat" do
      expect(placement_marks("e2 f d|e4|]", "C4|C4|]")).to eq ["1:3:000 to 1:4:000", "1:4:000 to 2:1:000"]
    end
  end

  describe "a nota cambiata" do
    it "is recognized from the downbeat" do
      expect(placement_marks("c' b g a|b4|]", "C4|G,4|]")).to eq []
    end

    # B is a seventh over C.
    it "is refused from beat 2, marking its dissonance" do
      expect(placement_marks("e c' b g|a b d'2|]", "C4|D4|]")).to eq ["1:3:000 to 1:4:000"]
    end

    it "is recognized from beat 3" do
      expect(placement_marks("e2 c' b|g a b2|]", "C4|E4|]")).to eq []
    end

    # Fux's figure 87a: the first note is attacked on beat 3 and tied over,
    # and the dissonance falls on beat 2.
    it "is recognized from the downbeat with its first note tied over the barline" do
      expect(placement_marks("z2 c'2-|c' b g a|b4|]", "C4|C4|G,4|]")).to eq []
    end
  end

  describe "in cut time" do
    it "recognizes a double neighbor from the downbeat" do
      expect(placement_marks("e f d e|c4|]", "C4|C4|]", meter: "2/2")).to eq []
    end

    it "refuses a double neighbor from the second quarter" do
      expect(placement_marks("g e f d|e4|]", "C4|C4|]", meter: "2/2")).to eq ["1:2:000 to 1:2:960", "1:2:960 to 2:1:000"]
    end

    it "recognizes a nota cambiata from the downbeat and from the second half note" do
      expect(placement_marks("c' b g a|b4|]", "C4|G,4|]", meter: "2/2")).to eq []
      expect(placement_marks("e2 c' b|g a b2|]", "C4|E4|]", meter: "2/2")).to eq []
    end

    it "refuses a nota cambiata from the second quarter" do
      expect(placement_marks("e c' b g|a b d'2|]", "C4|D4|]", meter: "2/2")).to eq ["1:2:000 to 1:2:960"]
    end
  end

  # Four quarters do not fit in the bar, so the figure returns on the next
  # downbeat.
  describe "in three-four time" do
    it "recognizes a double neighbor in quarters from the downbeat" do
      expect(placement_marks("e f d|e2 g|c'3|]", "C3|C3|C3|]", meter: "3/4")).to eq []
    end

    it "refuses a double neighbor from beat 2" do
      expect(placement_marks("g e f|d e2|c'3|]", "C3|C3|C3|]", meter: "3/4")).to include "1:3:000 to 2:1:000"
    end

    it "refuses a double neighbor whose second neighbor is held over the barline" do
      expect(placement_marks("e f d-|d e2|c'3|]", "C3|C3|C3|]", meter: "3/4")).to eq ["1:2:000 to 1:3:000", "1:3:000 to 2:2:000"]
    end

    # The return falls on the next downbeat, but the neighbors are an eighth
    # and a half note, so they are not a bar's even beats after the main tone.
    it "refuses a double neighbor returning on the next downbeat in uneven values" do
      expect(placement_marks("e/ f/ d2|e3|]", "C3|C3|]", meter: "3/4")).to eq ["1:1:480 to 1:2:000", "1:2:000 to 2:1:000"]
    end

    # Even values, in dotted quarters, but the return falls after the next
    # downbeat rather than on it.
    it "refuses a double neighbor returning after the next downbeat" do
      expect(placement_marks("e3/2 f3/2|d3/2 e3/2|c'3|]", "C3|C3|C3|]", meter: "3/4")).to include "1:2:480 to 2:1:000"
    end
  end
end

# The note values the florid and free guidelines ask of a dissonance: a half
# note may only pass, and the dissonant notes of a cambiata or a double
# neighbor are quarter notes (Salzer and Schachter, pp. 103-105).
RSpec.shared_examples "dissonance figure note values" do
  def note_value_marks(upper, lower)
    flow = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nV:upper\n#{upper}\nV:lower\n#{lower}\n")
    assess(described_class, flow.voices.first).marks.map(&:code)
  end

  describe "a dissonant half note" do
    it "is accepted as a passing tone" do
      expect(note_value_marks("e2 f2|g4|]", "C4|C4|]")).to eq []
    end

    # The same fourth over C, returning instead of passing.
    it "is marked as a neighbor tone" do
      expect(note_value_marks("e2 f2|e4|]", "C4|C4|]")).to eq ["1:3:000 to 2:1:000"]
    end
  end

  it "accepts a quarter-note neighbor tone" do
    expect(note_value_marks("e f e g|c'4|]", "C4|C4|]")).to eq []
  end

  describe "a nota cambiata" do
    # Placed from the downbeat; only the half note is at fault.
    it "is refused where its dissonance is a half note" do
      expect(note_value_marks("c'2 b2|g a b2|]", "C4|E4|]")).to eq ["1:3:000 to 2:1:000"]
    end

    # Placed from beat 3; B is a seventh over C, and it leaps from an eighth.
    it "is refused where its dissonance is an eighth note" do
      expect(note_value_marks("e2 c'/ b/ g|a b3|]", "C4|D4|]")).to eq ["1:3:480 to 1:4:000"]
    end

    it "is recognized with a long consonant note after its leap" do
      expect(note_value_marks("c' b g2|a b3|]", "C4|D4|]")).to eq []
    end
  end

  describe "a double neighbor" do
    # Placed from the downbeat; F is a fourth and D a ninth over C.
    it "is refused in eighth notes, marking both neighbors" do
      expect(note_value_marks("e/ f/ d/ e/ c2|c4|]", "C4|C4|]")).to eq ["1:1:480 to 1:2:000", "1:2:000 to 1:2:480"]
    end

    it "is refused where one dissonant neighbor is an eighth, marking both" do
      expect(note_value_marks("e f d/ e/ c|c4|]", "C4|C4|]")).to eq ["1:2:000 to 1:3:000", "1:3:000 to 1:3:480"]
    end

    # G is a fifth over C, so the quarter-note B is the only dissonance.
    it "is recognized where the neighbor that is an eighth is consonant" do
      expect(note_value_marks("a b g/ a/ g|g4|]", "C4|C4|]")).to eq []
    end
  end
end
