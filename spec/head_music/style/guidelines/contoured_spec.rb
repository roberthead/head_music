require "spec_helper"

describe HeadMusic::Style::Guidelines::Contoured do
  subject { assess(described_class, voice, contour: contour) }

  let(:flow) { HeadMusic::Notation::ABC.parse(abc) }
  let(:voice) { flow.voices.first }

  let(:abc) do
    <<~ABC
      X:1
      M:4/4
      L:1/4
      K:C
      #{melody}
    ABC
  end

  def self.misses_by_degree(examples)
    examples.each do |description, (shape, degree, miss)|
      context "with #{description}" do
        let(:melody) { shape }

        its(:fitness) { is_expected.to eq HeadMusic::GOLDEN_RATIO_INVERSE**(2 * degree) }
        its(:marks_count) { is_expected.to eq 1 }
        its(:violation_key) { is_expected.to eq "guidelines.contoured.violations.#{miss}" }

        it "declares the key it chose" do
          expect(described_class.violation_keys(contour: contour)).to include("guidelines.contoured.violations.#{miss}")
        end
      end
    end
  end

  describe ".with" do
    subject(:configured) { described_class.with(:arch) }

    it { is_expected.to be_a HeadMusic::Style::GuideItem }
    its(:guideline) { is_expected.to eq described_class }
    its(:config) { is_expected.to eq(contour: :arch) }

    it "accepts a string key" do
      expect(described_class.with("Arch").config).to eq(contour: :arch)
    end

    it "raises for an unknown contour" do
      expect { described_class.with(:zigzag) }.to raise_error(ArgumentError, /zigzag/)
    end
  end

  describe ".violation_keys" do
    it "declares only the default for static" do
      expect(described_class.violation_keys(contour: :static)).to eq ["guidelines.contoured.violations.default"]
    end

    it "declares only the default and too few legs for a wave" do
      expect(described_class.violation_keys(contour: :wave)).to eq %w[
        guidelines.contoured.violations.default
        guidelines.contoured.violations.too_few_legs
      ]
    end
  end

  describe "#message" do
    let(:contour) { :arch }
    let(:melody) { "CDEF|G4|" }

    its(:message) { is_expected.to eq "Write the arch contour: add a fall of at least a minor third." }
  end

  context "when constructed directly with an unknown contour" do
    let(:melody) { "CDEF|G4|" }

    it "raises when evaluated" do
      expect { assess(described_class, voice, contour: :bogus) }.to raise_error(ArgumentError, /bogus/)
    end
  end

  context "when configured for an ascending contour" do
    let(:contour) { :ascending }

    {
      "an undulating melody from floor to ceiling" => "CDED|EFEF|G4|",
      "a melody that revisits its opening floor pitch" => "CDCE|FGA2|",
      "a scale" => "CDEF|GABc|",
      "a scale ending a half step below its climax" => "CDEF|GABc|B4|",
      "a start a whole step above the floor and an end a whole step below the ceiling" => "DCEG|AG2|",
      "five legs from floor to ceiling" => "CDEC|DEFD|EGA2|"
    }.each do |description, shape|
      context "with #{description}" do
        let(:melody) { shape }

        it { is_expected.to be_adherent }
      end
    end

    misses_by_degree(
      "a scale ending a minor third below its climax" => ["CDEF|GABc|A4|", 1, :ascending_end],
      "a start a major third above the floor" => ["EDCD|EFGA|", 1, :ascending_start],
      "both endpoints a minor third or more from the extremes" => ["EDCE|GABc|A4|", 2, :ascending_start_and_end],
      "a level line whose endpoints sit near its extremes" => ["EDEF|EFED|E4|", 1, :ascending_rise],
      "whole-step undulation" => ["CDCD|C4|", 1, :ascending_rise],
      "an arching melody" => ["CDEG|EDC2|", 2, :ascending_rise],
      "a descending scale" => ["cBAG|FEDC|", 3, :ascending_rise]
    )
  end

  context "when configured for a descending contour" do
    let(:contour) { :descending }

    {
      "an undulating melody from ceiling to floor" => "GFEF|EDED|C4|",
      "a scale" => "cBAG|FEDC|",
      "a scale ending a half step above its nadir" => "cBAG|FEDC|D4|",
      "a start a whole step below the ceiling and an end a whole step above the floor" => "GAFD|CD2|"
    }.each do |description, shape|
      context "with #{description}" do
        let(:melody) { shape }

        it { is_expected.to be_adherent }
      end
    end

    misses_by_degree(
      "a scale ending a minor third above its nadir" => ["cBAG|FEDC|E4|", 1, :descending_end],
      "a start a fourth below the ceiling" => ["GAcB|AGFE|DC2|", 1, :descending_start],
      "both endpoints a minor third or more from the extremes" => ["GAcB|AGFE|DCE2|", 2, :descending_start_and_end],
      "a level line whose endpoints sit near its extremes" => ["EDEF|EFED|E4|", 1, :descending_fall],
      "whole-step undulation" => ["CDCD|C4|", 1, :descending_fall],
      "a valley" => ["GFED|CDEF|G4|", 2, :descending_fall],
      "an ascending melody" => ["CDED|EFG2|", 3, :descending_fall]
    )
  end

  context "when configured for an arch contour" do
    let(:contour) { :arch }

    context "with a single interior climax" do
      let(:melody) { "CDEG|EDC2|" }

      it { is_expected.to be_adherent }
    end

    context "with a repeated interior climax" do
      let(:melody) { "CDEG|GEDC|" }

      it { is_expected.to be_adherent }

      it "leaves climax multiplicity to ConsonantClimax" do
        expect(assess(HeadMusic::Style::Guidelines::ConsonantClimax, voice)).not_to be_adherent
      end
    end

    context "with a long rise and fall" do
      let(:melody) { "CDEF|GAGF|EDC2|" }

      it { is_expected.to be_adherent }
    end

    context "with a neighbor-note dip on the way up" do
      let(:melody) { "CDED|EFGF|EDC2|" }

      it { is_expected.to be_adherent }
    end

    context "with a closing step against the descent" do
      let(:melody) { "CEGF|EDCB,|C4|" }

      it { is_expected.to be_adherent }
    end

    misses_by_degree(
      "a rise, a plunge, and a climb back" => ["CDED|B,A,G,B,|C4|", 1, :extra_legs],
      "a rise, fall, and rise" => ["CEGA|GDB,D|", 1, :extra_legs],
      "a fall, rise, and fall" => ["GECD|EGFD|", 1, :extra_legs],
      "the climax at the last note" => ["CDEF|G4|", 1, :missing_fall],
      "a descending line" => ["GFED|C4|", 1, :missing_rise],
      "a four-leg wave" => ["CDED|CDEF|EDC2|", 2, :extra_legs],
      "a valley" => ["GFED|CDEF|", 2, :reversed_legs],
      "undulation below the leg threshold" => ["CDCD|C4|", 2, :missing_legs]
    )
  end

  context "when configured for a valley contour" do
    let(:contour) { :valley }

    context "with an interior nadir" do
      let(:melody) { "GFEC|DEFG|" }

      it { is_expected.to be_adherent }
    end

    context "with a repeated interior nadir" do
      let(:melody) { "CB,A,G,|G,A,B,C|" }

      it { is_expected.to be_adherent }

      it "leaves nadir multiplicity to ConsonantClimax" do
        expect(assess(HeadMusic::Style::Guidelines::ConsonantClimax, voice)).not_to be_adherent
      end
    end

    context "with a fall and rise between the same pitch" do
      let(:melody) { "GFED|CDEF|G4|" }

      it { is_expected.to be_adherent }
    end

    misses_by_degree(
      "a rise, a plunge, and a climb back" => ["CDED|B,A,G,B,|C4|", 1, :extra_legs],
      "the nadir at the last note" => ["GFED|C4|", 1, :missing_rise],
      "an ascending line" => ["CDEF|G4|", 1, :missing_fall],
      "an arch" => ["CDEG|EDC2|", 2, :reversed_legs],
      "an arch whose close dips below its opening" => ["CEGF|EDCB,|C4|", 2, :reversed_legs]
    )
  end

  context "when configured for a wave contour" do
    let(:contour) { :wave }

    context "with three legs" do
      let(:melody) { "CDED|CDE2|" }

      it { is_expected.to be_adherent }
    end

    context "with a rise, a plunge, and a climb back" do
      let(:melody) { "CDED|B,A,G,B,|C4|" }

      it { is_expected.to be_adherent }
    end

    context "with a rest in the middle of three legs" do
      let(:melody) { "CDED|zCDE|" }

      it { is_expected.to be_adherent }
    end

    context "with legs of exactly a minor third" do
      let(:melody) { "DFDF|D4|" }

      it { is_expected.to be_adherent }
    end

    misses_by_degree(
      "a single-turn arch" => ["CDEG|EDC2|", 1, :too_few_legs],
      "an ascending line" => ["CDEF|G4|", 2, :too_few_legs],
      "whole-step undulation below the leg threshold" => ["CDCD|C4|", 3, :too_few_legs]
    )
  end

  context "when configured for a static contour" do
    let(:contour) { :static }

    context "with a narrow range and neutral endpoints" do
      let(:melody) { "EDEF|EFED|E4|" }

      it { is_expected.to be_adherent }
    end

    context "with a single repeated pitch" do
      let(:melody) { "EEEE|E4|" }

      it { is_expected.to be_adherent }
    end

    context "with a range of exactly a major third and neutral endpoints" do
      let(:melody) { "DCDE|D4|" }

      it { is_expected.to be_adherent }
    end

    context "with a range wider than a major third" do
      let(:melody) { "CDEF|G4|" }

      it { is_expected.not_to be_adherent }
      its(:fitness) { is_expected.to eq HeadMusic::GOLDEN_RATIO_INVERSE**2 }
      its(:marks_count) { is_expected.to eq 1 }
    end

    context "with a narrow range but endpoints implying an ascending contour" do
      let(:melody) { "CDCD|E4|" }

      it { is_expected.not_to be_adherent }
    end

    context "with a narrow range but endpoints implying a descending contour" do
      let(:melody) { "EDED|C4|" }

      it { is_expected.not_to be_adherent }
    end

    context "with an end a whole step from the ceiling" do
      let(:melody) { "CDED|" }

      it { is_expected.to be_adherent }
    end
  end

  describe "arch, valley, and wave" do
    shapes = {
      "a three-note arch" => ["CEC2|", :arch],
      "a long rise and fall" => ["CDEF|GAGF|EDC2|", :arch],
      "an arch with a neighbor-note dip on the way up" => ["CDED|EFGF|EDC2|", :arch],
      "an arch with a closing step against the descent" => ["CEGF|EDCB,|C4|", :arch],
      "an arch with a repeated climax" => ["CDEG|GEDC|", :arch],
      "a three-note valley" => ["ECE2|", :valley],
      "a valley" => ["GFED|CDEF|G4|", :valley],
      "a valley with a repeated nadir" => ["GFEC|CDEG|", :valley],
      "a rise, a plunge, and a climb back" => ["CDED|B,A,G,B,|C4|", :wave],
      "a three-leg wave" => ["CDED|CDE2|", :wave],
      "a wave of minor thirds" => ["DFDF|D4|", :wave],
      "a four-leg wave with a single peak" => ["CDED|CDEF|EDC2|", :wave],
      "a repeated climax a third apart" => ["CDGE|GEDC|", :wave],
      "undulation below the leg threshold" => ["CDCD|C4|", nil],
      "a line climaxing on its last note" => ["CDEF|G4|", nil]
    }

    shapes.each do |description, (shape, expected)|
      context "with #{description}" do
        let(:melody) { shape }
        let(:matching_contours) do
          %i[arch valley wave].select { |key| assess(described_class, voice, contour: key).adherent? }
        end

        it { expect(matching_contours).to eq Array(expected) }
      end
    end
  end

  context "when there are no notes" do
    let(:voice) { HeadMusic::Content::Voice.new }

    described_class::CONTOURS.each do |contour_key|
      context "with the #{contour_key} contour" do
        let(:contour) { contour_key }

        it { is_expected.to be_adherent }
      end
    end
  end

  context "with a single note" do
    let(:melody) { "C4|" }

    context "with the static contour" do
      let(:contour) { :static }

      it { is_expected.to be_adherent }
    end

    %i[ascending descending].each do |contour_key|
      context "with the #{contour_key} contour" do
        let(:contour) { contour_key }

        its(:fitness) { is_expected.to eq HeadMusic::GOLDEN_RATIO_INVERSE**2 }
      end
    end

    {arch: [2, :missing_legs], valley: [2, :missing_legs], wave: [3, :too_few_legs]}.each do |contour_key, (degree, miss)|
      context "with the #{contour_key} contour" do
        let(:contour) { contour_key }

        its(:fitness) { is_expected.to eq HeadMusic::GOLDEN_RATIO_INVERSE**(2 * degree) }
        its(:violation_key) { is_expected.to eq "guidelines.contoured.violations.#{miss}" }
      end
    end
  end

  context "with two notes" do
    let(:melody) { "C2D2|" }

    {arch: [2, :missing_legs], valley: [2, :missing_legs], wave: [3, :too_few_legs]}.each do |contour_key, (degree, miss)|
      context "with the #{contour_key} contour" do
        let(:contour) { contour_key }

        its(:fitness) { is_expected.to eq HeadMusic::GOLDEN_RATIO_INVERSE**(2 * degree) }
        its(:violation_key) { is_expected.to eq "guidelines.contoured.violations.#{miss}" }
      end
    end
  end
end
