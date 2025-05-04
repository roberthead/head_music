require "spec_helper"

describe HeadMusic::Analysis::PitchClassSet do
  context "when the set has zero pitch classes" do
    subject(:set) { described_class.new([]) }

    it { is_expected.to be_empty }
    it { is_expected.to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }
  end

  context "when the set has one pitch class" do
    subject(:set) { described_class.new(["A"]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }

    it { is_expected.to be_a(described_class) }

    its(:inspect) { is_expected.to eq "[9]" }
    its(:to_s) { is_expected.to eq "[9]" }

    specify do
      expect(set).to be_equivalent(described_class.new(["Bbb"]))
    end
  end

  context "when the set has two pitches" do
    subject(:set) { described_class.new(%w[A3 D4]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }
  end

  context "when the set has three pitches" do
    subject(:set) { described_class.new(%w[F#3 D4 A4]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }

    its(:inspect) { is_expected.to eq "[2, 6, 9]" }
    its(:to_s) { is_expected.to eq "[2, 6, 9]" }
  end

  context "when the set has nine pitches and seven pitch classes" do
    subject(:set) { described_class.new(%w[C D E F G A B C5 D5]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }
  end

  context "when the set has nine unique pitches classes" do
    subject(:set) { described_class.new(%w[C D E F G A B C#5 F#5]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }
  end
end
