require "spec_helper"

describe HeadMusic::Rudiment::RhythmicUnit do
  subject(:rhythmic_unit) { described_class.get(name) }

  %w[maxima longa breve whole half quarter eighth sixteenth thirty-second].each do |name|
    context "with #{name}" do
      let(:name) { name.to_sym }

      it "is a valid rhythmic unit" do
        expect(described_class.valid_name?(name)).to be true
      end

      it "is included in all rhythmic units" do
        expect(described_class.all.map(&:british_name)).to include(rhythmic_unit.british_name)
      end
    end
  end

  context "for :whole" do
    let(:name) { :whole }

    its(:relative_value) { is_expected.to eq 1.0 }
    its(:notehead) { is_expected.to eq :open }
    it { is_expected.not_to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "semibreve" }

    it { is_expected.to be > described_class.get(:half) }
    it { is_expected.to be < described_class.get(:breve) }
  end

  context "for :half" do
    let(:name) { :half }

    its(:relative_value) { is_expected.to eq 0.5 }
    its(:notehead) { is_expected.to eq :open }
    it { is_expected.to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "minim" }
  end

  context "for :quarter" do
    let(:name) { :quarter }

    its(:relative_value) { is_expected.to eq 0.25 }
    its(:notehead) { is_expected.to eq :closed }
    it { is_expected.to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "crotchet" }
  end

  context "for :eighth" do
    let(:name) { :eighth }

    its(:relative_value) { is_expected.to eq 0.125 }
    its(:notehead) { is_expected.to eq :closed }
    it { is_expected.to be_stemmed }
    its(:flags) { are_expected.to eq 1 }
    its(:british_name) { is_expected.to eq "quaver" }
  end

  context "for :sixteenth" do
    let(:name) { :sixteenth }

    its(:relative_value) { is_expected.to eq 0.0625 }
    its(:notehead) { is_expected.to eq :closed }
    it { is_expected.to be_stemmed }
    its(:flags) { are_expected.to eq 2 }
    its(:british_name) { is_expected.to eq "semiquaver" }
    it { is_expected.to be_common }
  end

  context "for thirty-second" do
    let(:name) { "thirty-second" }

    its(:relative_value) { is_expected.to eq 1.0 / 32 }
    its(:notehead) { is_expected.to eq :closed }
    it { is_expected.to be_stemmed }
    its(:flags) { are_expected.to eq 3 }
    its(:british_name) { is_expected.to eq "demisemiquaver" }
    it { is_expected.to be_common }
  end

  context 'for "double whole"' do
    let(:name) { "double whole" }

    its(:relative_value) { is_expected.to eq 2.0 }
    its(:notehead) { is_expected.to eq :breve }
    it { is_expected.not_to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "breve" }
  end

  context 'for "breve"' do
    let(:name) { "breve" }

    its(:relative_value) { is_expected.to eq 2.0 }
    its(:notehead) { is_expected.to eq :breve }
    it { is_expected.not_to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "breve" }
    it { is_expected.not_to be_common }
  end

  context 'for "longa"' do
    let(:name) { "longa" }

    its(:relative_value) { is_expected.to eq 4.0 }
    its(:notehead) { is_expected.to eq :longa }
    it { is_expected.not_to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "longa" }
  end

  context 'for "maxima"' do
    let(:name) { "maxima" }

    its(:relative_value) { is_expected.to eq 8.0 }
    its(:notehead) { is_expected.to eq :maxima }
    it { is_expected.not_to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "maxima" }
  end

  describe ".for_denominator_value" do
    context "with valid power-of-2 denominators" do
      it "returns whole note for denominator 1" do
        expect(described_class.for_denominator_value(1)).to eq described_class.get(:whole)
      end

      it "returns half note for denominator 2" do
        expect(described_class.for_denominator_value(2)).to eq described_class.get(:half)
      end

      it "returns quarter note for denominator 4" do
        expect(described_class.for_denominator_value(4)).to eq described_class.get(:quarter)
      end

      it "returns eighth note for denominator 8" do
        expect(described_class.for_denominator_value(8)).to eq described_class.get(:eighth)
      end

      it "returns sixteenth note for denominator 16" do
        expect(described_class.for_denominator_value(16)).to eq described_class.get(:sixteenth)
      end

      it "returns thirty-second note for denominator 32" do
        expect(described_class.for_denominator_value(32)).to eq described_class.get("thirty-second")
      end

      it "returns sixty-fourth note for denominator 64" do
        expect(described_class.for_denominator_value(64)).to eq described_class.get("sixty-fourth")
      end
    end

    context "with invalid non-power-of-2 denominators" do
      it "returns nil for denominator 3" do
        expect(described_class.for_denominator_value(3)).to be_nil
      end

      it "returns nil for denominator 5" do
        expect(described_class.for_denominator_value(5)).to be_nil
      end

      it "returns nil for denominator 6" do
        expect(described_class.for_denominator_value(6)).to be_nil
      end

      it "returns nil for denominator 7" do
        expect(described_class.for_denominator_value(7)).to be_nil
      end

      it "returns nil for denominator 12" do
        expect(described_class.for_denominator_value(12)).to be_nil
      end
    end

    context "with invalid input types" do
      it "returns nil for nil input" do
        expect(described_class.for_denominator_value(nil)).to be_nil
      end

      it "returns nil for string input" do
        expect(described_class.for_denominator_value("4")).to be_nil
      end

      it "returns nil for array input" do
        expect(described_class.for_denominator_value([4])).to be_nil
      end

      it "returns nil for hash input" do
        expect(described_class.for_denominator_value({})).to be_nil
      end
    end

    context "with boundary conditions" do
      it "returns nil for zero" do
        expect(described_class.for_denominator_value(0)).to be_nil
      end

      it "returns nil for negative numbers" do
        expect(described_class.for_denominator_value(-1)).to be_nil
        expect(described_class.for_denominator_value(-4)).to be_nil
      end

      it "returns nil for very large power-of-2 values beyond the available divisions" do
        # Test with 2^10 = 1024, which should exceed AMERICAN_DIVISIONS_NAMES.length
        expect(described_class.for_denominator_value(1024)).to be_nil
      end

      it "raises NoMethodError for floating point numbers due to bitwise operation" do
        expect { described_class.for_denominator_value(4.0) }.to raise_error(NoMethodError, /undefined method `&' for an instance of Float/)
      end
    end

    context "with edge cases for largest valid denominator" do
      # Test the largest valid denominator based on AMERICAN_DIVISIONS_NAMES length
      let(:max_index) { described_class::AMERICAN_DIVISIONS_NAMES.length - 1 }
      let(:max_denominator) { 2**max_index }

      it "returns the correct rhythmic unit for the largest valid denominator" do
        result = described_class.for_denominator_value(max_denominator)
        expect(result).to eq described_class.get(described_class::AMERICAN_DIVISIONS_NAMES[max_index])
      end

      it "returns nil for denominator just beyond the maximum" do
        beyond_max = 2**(max_index + 1)
        expect(described_class.for_denominator_value(beyond_max)).to be_nil
      end
    end
  end

  describe ".get" do
    context "when given an instance" do
      let(:instance) { described_class.get(:quarter) }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe ".new" do
    it "is private" do
      expect { described_class.new(5) }.to raise_error NoMethodError
    end

    it "raises ArgumentError for nil or empty name" do
      expect { described_class.send(:new, nil) }.to raise_error(ArgumentError, "Name cannot be nil or empty")
      expect { described_class.send(:new, "") }.to raise_error(ArgumentError, "Name cannot be nil or empty")
    end
  end
end
