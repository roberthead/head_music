require "spec_helper"

describe HeadMusic::Style::Guidelines::Contoured do
  subject { described_class.with(contour).new(voice) }

  let(:composition) { HeadMusic::Notation::ABC.parse(abc) }
  let(:voice) { composition.voices.first }

  let(:abc) do
    <<~ABC
      X:1
      M:4/4
      L:1/4
      K:C
      #{melody}
    ABC
  end

  describe ".with" do
    subject(:configured) { described_class.with(:arch) }

    it { is_expected.to be_a HeadMusic::Style::Annotation::Configured }
    its(:guideline_class) { is_expected.to eq described_class }
    its(:options) { is_expected.to eq(contour: :arch) }

    it "accepts a string key" do
      expect(described_class.with("Arch").options).to eq(contour: :arch)
    end

    it "raises for an unknown contour" do
      expect { described_class.with(:zigzag) }.to raise_error(ArgumentError, /zigzag/)
    end

    it "accepts a weight option" do
      annotation = described_class.with(:arch, weight: 0.5).new(HeadMusic::Content::Voice.new)
      expect(annotation.weight).to eq 0.5
    end
  end

  describe ".default_weight" do
    it "is the inverse golden ratio" do
      expect(described_class.default_weight).to eq HeadMusic::GOLDEN_RATIO_INVERSE
    end
  end

  describe "#message" do
    let(:contour) { :arch }
    let(:melody) { "CDEF|G4|" }

    its(:message) { is_expected.to eq "Write a melody with the arch contour." }
  end

  context "when constructed directly with an unknown contour" do
    let(:melody) { "CDEF|G4|" }

    it "raises when evaluated" do
      annotation = described_class.new(voice, contour: :bogus)
      expect { annotation.fitness }.to raise_error(ArgumentError, /bogus/)
    end
  end

  context "when configured for an ascending contour" do
    let(:contour) { :ascending }

    context "with an undulating melody from floor to ceiling" do
      let(:melody) { "CDED|EFEF|G4|" }

      it { is_expected.to be_adherent }
    end

    context "with a melody that revisits its opening floor pitch" do
      let(:melody) { "CDCE|FGA2|" }

      it { is_expected.to be_adherent }
    end

    context "with an arching melody" do
      let(:melody) { "CDEG|EDC2|" }

      it { is_expected.not_to be_adherent }
      its(:fitness) { is_expected.to eq HeadMusic::GOLDEN_RATIO_INVERSE**2 }
      its(:marks_count) { is_expected.to eq 1 }
      its(:message) { is_expected.to eq "Write a melody with the ascending contour." }
    end
  end

  context "when configured for a descending contour" do
    let(:contour) { :descending }

    context "with an undulating melody from ceiling to floor" do
      let(:melody) { "GFEF|EDED|C4|" }

      it { is_expected.to be_adherent }
    end

    context "with an ascending melody" do
      let(:melody) { "CDED|EFG2|" }

      it { is_expected.not_to be_adherent }
      its(:fitness) { is_expected.to eq HeadMusic::GOLDEN_RATIO_INVERSE**2 }
      its(:marks_count) { is_expected.to eq 1 }
    end
  end

  context "when configured for an arch contour" do
    let(:contour) { :arch }

    context "with a single interior climax" do
      let(:melody) { "CDEG|EDC2|" }

      it { is_expected.to be_adherent }
    end

    context "with a repeated interior climax" do
      let(:melody) { "CDGE|GEDC|" }

      it { is_expected.to be_adherent }

      it "leaves climax multiplicity to ConsonantClimax" do
        expect(HeadMusic::Style::Guidelines::ConsonantClimax.new(voice)).not_to be_adherent
      end
    end

    context "with the climax at the last note" do
      let(:melody) { "CDEF|G4|" }

      it { is_expected.not_to be_adherent }
      its(:fitness) { is_expected.to eq HeadMusic::GOLDEN_RATIO_INVERSE**2 }
      its(:marks_count) { is_expected.to eq 1 }
    end
  end

  context "when configured for a valley contour" do
    let(:contour) { :valley }

    context "with an interior nadir" do
      let(:melody) { "GFEC|DEFG|" }

      it { is_expected.to be_adherent }
    end

    context "with a repeated interior nadir" do
      let(:melody) { "cAEG|EGAc|" }

      it { is_expected.to be_adherent }

      it "leaves nadir multiplicity to ConsonantClimax" do
        expect(HeadMusic::Style::Guidelines::ConsonantClimax.new(voice)).not_to be_adherent
      end
    end

    context "with the nadir at the last note" do
      let(:melody) { "GFED|C4|" }

      it { is_expected.not_to be_adherent }
      its(:fitness) { is_expected.to eq HeadMusic::GOLDEN_RATIO_INVERSE**2 }
      its(:marks_count) { is_expected.to eq 1 }
    end
  end

  context "when configured for a wave contour" do
    let(:contour) { :wave }

    context "with three trend legs" do
      let(:melody) { "CDED|CDE2|" }

      it { is_expected.to be_adherent }
    end

    context "with a rest in the middle of three trend legs" do
      let(:melody) { "CDED|zCDE|" }

      it { is_expected.to be_adherent }
    end

    context "with trend legs of exactly a minor third" do
      let(:melody) { "DFDF|D4|" }

      it { is_expected.to be_adherent }
    end

    context "with a single-turn arch" do
      let(:melody) { "CDEG|EDC2|" }

      it { is_expected.not_to be_adherent }
      its(:fitness) { is_expected.to eq HeadMusic::GOLDEN_RATIO_INVERSE**2 }
      its(:marks_count) { is_expected.to eq 1 }
    end

    context "with whole-step undulation below the trend threshold" do
      let(:melody) { "CDCD|C4|" }

      it { is_expected.not_to be_adherent }
    end
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
  end

  context "when there are no notes" do
    subject { described_class.with(contour).new(voice) }

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

    %i[ascending descending static].each do |contour_key|
      context "with the #{contour_key} contour" do
        let(:contour) { contour_key }

        it { is_expected.to be_adherent }
      end
    end

    %i[arch valley wave].each do |contour_key|
      context "with the #{contour_key} contour" do
        let(:contour) { contour_key }

        it { is_expected.not_to be_adherent }
      end
    end
  end

  context "with two notes" do
    let(:melody) { "C2D2|" }

    %i[arch valley wave].each do |contour_key|
      context "with the #{contour_key} contour" do
        let(:contour) { contour_key }

        it { is_expected.not_to be_adherent }
      end
    end
  end
end
