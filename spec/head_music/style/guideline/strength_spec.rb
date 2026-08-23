require "spec_helper"

describe HeadMusic::Style::Guideline::Strength do
  let(:guidelines) { HeadMusic::Style::Guidelines }

  # Named before the body runs rather than left anonymous, so the messages under
  # test read the way a real `class Foo < Guideline` declaration's would.
  def declare(&body)
    stub_const("SomeGuideline", Class.new(HeadMusic::Style::Guideline)).tap { |klass| klass.class_eval(&body) }
  end

  describe "the declaration" do
    it "defaults to strong, so the axis is opt-in" do
      expect(guidelines::NoParallelPerfectOnDownbeats.strength).to eq :strong
    end

    it "reads back what a guideline declared" do
      expect(guidelines::PreferContraryMotion.strength).to eq :weak
    end

    it "requires a reason for weak, so every weak call carries one by construction" do
      expect { declare { strength :weak } }
        .to raise_error(ArgumentError, /SomeGuideline declares strength :weak and must say why with because:/)
    end

    it "rejects a reason for strong, which is the default and needs no defending" do
      expect { declare { strength :strong, because: "why not" } }
        .to raise_error(ArgumentError, /SomeGuideline declares strength :strong.*takes no because:/)
    end

    it "rejects an unrecognized value, naming the guideline and what it allows" do
      expect { declare { strength :medium } }
        .to raise_error(ArgumentError, /SomeGuideline strength must be one of: strong, weak \(got :medium\)/)
    end

    it "normalizes the spelling, so a string or a capital reads the same" do
      expect(declare { strength "WEAK", because: "a reason" }.strength).to eq :weak
    end
  end

  # Never inherited: WeakBeatDissonanceTreatment bases two treatments that are
  # the taught rule of their own guides, and MinimumThreshold bases both a gate
  # and a rubric item. One careless declaration on a shared analysis base would
  # otherwise demote several taught rules silently.
  describe "inheritance" do
    it "does not pass a declaration down to a subclass" do
      base = declare { strength :weak, because: "a reason" }

      expect(Class.new(base).strength).to eq :strong
    end

    it "leaves the dissonance treatments strong despite their weak-named base" do
      expect(guidelines::WeakBeatDissonanceTreatment.strength).to eq :strong
      expect(guidelines::ThirdSpeciesDissonanceTreatment.strength).to eq :strong
      expect(guidelines::TripleMeterDissonanceTreatment.strength).to eq :strong
    end
  end

  describe ".units" do
    it "weighs a prohibition twice a preference" do
      expect(described_class.units(:strong)).to eq(2 * described_class.units(:weak))
    end

    # fetch rather than [], so a strength that slipped past normalization raises
    # instead of multiplying a weight by nil.
    it "raises on a strength it does not know" do
      expect { described_class.units(:medium) }.to raise_error(KeyError)
    end
  end
end
