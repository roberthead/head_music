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
end
