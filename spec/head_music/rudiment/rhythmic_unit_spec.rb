require "spec_helper"

describe HeadMusic::Rudiment::RhythmicUnit do
  subject(:rhythmic_unit) { described_class.get(name) }

  context "for :whole" do
    let(:name) { :whole }

    its(:relative_value) { is_expected.to eq 1 }
    its(:notehead) { is_expected.to eq :open }
    it { is_expected.not_to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "semibreve" }
  end

  context "for :half" do
    let(:name) { :half }

    its(:relative_value) { is_expected.to eq 1.0 / 2 }
    its(:notehead) { is_expected.to eq :open }
    it { is_expected.to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "minim" }
  end

  context "for :quarter" do
    let(:name) { :quarter }

    its(:relative_value) { is_expected.to eq 1.0 / 4 }
    its(:notehead) { is_expected.to eq :closed }
    it { is_expected.to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "crotchet" }
  end

  context "for :eighth" do
    let(:name) { :eighth }

    its(:relative_value) { is_expected.to eq 1.0 / 8 }
    its(:notehead) { is_expected.to eq :closed }
    it { is_expected.to be_stemmed }
    its(:flags) { are_expected.to eq 1 }
    its(:british_name) { is_expected.to eq "quaver" }
  end

  context "for :sixteenth" do
    let(:name) { :sixteenth }

    its(:relative_value) { is_expected.to eq 1.0 / 16 }
    its(:notehead) { is_expected.to eq :closed }
    it { is_expected.to be_stemmed }
    its(:flags) { are_expected.to eq 2 }
    its(:british_name) { is_expected.to eq "semiquaver" }
  end

  context "for thirty-second" do
    let(:name) { "thirty-second" }

    its(:relative_value) { is_expected.to eq 1.0 / 32 }
    its(:notehead) { is_expected.to eq :closed }
    it { is_expected.to be_stemmed }
    its(:flags) { are_expected.to eq 3 }
    its(:british_name) { is_expected.to eq "demisemiquaver" }
  end

  context 'for "double whole"' do
    let(:name) { "double whole" }

    its(:relative_value) { is_expected.to eq 2 }
    its(:notehead) { is_expected.to eq :breve }
    it { is_expected.not_to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "breve" }
  end

  context 'for "breve"' do
    let(:name) { "breve" }

    its(:relative_value) { is_expected.to eq 2 }
    its(:notehead) { is_expected.to eq :breve }
    it { is_expected.not_to be_stemmed }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq "breve" }
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
  end
end
