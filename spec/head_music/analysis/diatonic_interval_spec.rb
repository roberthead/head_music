require "spec_helper"

I18n.describe HeadMusic::Analysis::DiatonicInterval do
  # rubocop:disable RSpec/MultipleMemoizedHelpers
  let(:c_flat_4) { HeadMusic::Rudiment::Pitch.get("Cb") }
  let(:c_4) { HeadMusic::Rudiment::Pitch.get("C") }
  let(:c_sharp_4) { HeadMusic::Rudiment::Pitch.get("C#") }
  let(:e_4) { HeadMusic::Rudiment::Pitch.get("E") }
  let(:e_flat_4) { HeadMusic::Rudiment::Pitch.get("Eb") }
  let(:c_5) { HeadMusic::Rudiment::Pitch.get("C5") }

  let(:maj3) { described_class.get(:major_third) }
  let(:min3) { described_class.get(:minor_third) }
  let(:dim3) { described_class.get(:diminished_third) }
  let(:aug3) { described_class.get(:augmented_third) }
  let(:aug4) { described_class.get(:augmented_fourth) }
  let(:dim5) { described_class.get("diminished fifth") }
  let(:p5) { described_class.get(:perfect_fifth) }
  let(:dim8) { described_class.get(:diminished_octave) }
  let(:perf8) { described_class.get(:perfect_octave) }
  let(:aug8) { described_class.get(:augmented_octave) }
  let(:p15) { described_class.get(:perfect_fifteenth) }

  describe "constructor" do
    specify { expect(described_class.new(c_sharp_4, e_4).name).to eq min3.name }
    specify { expect(described_class.new(c_4, e_4).name).to eq maj3.name }
    specify { expect(described_class.new(c_flat_4, e_4).name).to eq aug3.name }
    specify { expect(described_class.new(c_sharp_4, e_flat_4).name).to eq dim3.name }
    specify { expect(described_class.new(c_sharp_4, c_5).name).to eq dim8.name }
    specify { expect(described_class.new(c_4, c_5).name).to eq perf8.name }
    specify { expect(described_class.new(c_flat_4, c_5).name).to eq aug8.name }
  end

  describe ".get" do
    describe "when passed a known descriptive string" do
      it "recognizes the interval" do
        expect(described_class.get("minor third")).to eq min3
      end

      describe "assuming middle C" do
        specify { expect(maj3.lower_pitch).to eq "C4" }
        specify { expect(maj3.higher_pitch).to eq "E4" }

        specify { expect(aug4.lower_pitch).to eq "C4" }
        specify { expect(aug4.higher_pitch).to eq "F#4" }

        specify { expect(dim5.lower_pitch).to eq "C4" }
        specify { expect(dim5.higher_pitch).to eq "Gb4" }
        specify { expect(dim5.quality_name).to eq "diminished" }

        specify { expect(dim8.lower_pitch).to eq "C4" }
        specify { expect(dim8.higher_pitch).to eq "Cb5" }
        specify { expect(dim8.simple_number).to eq 8 }
        specify { expect(dim8.quality_name).to eq "diminished" }

        specify { expect(p15.higher_pitch).to eq "C6" }
        specify { expect(p15.number).to eq 15 }
        specify { expect(p15.simple_number).to eq 8 }
        specify { expect(p15.quality_name).to eq "perfect" }
      end
    end

    describe "when passed a known abbreviation" do
      specify { expect(described_class.get("P5")).to eq p5 }
      specify { expect(described_class.get("M3")).to eq maj3 }
      specify { expect(described_class.get("m3")).to eq min3 }
      specify { expect(described_class.get("A4")).to eq aug4 }
      specify { expect(described_class.get("d5")).to eq dim5 }
      specify { expect(described_class.get("M10").name).to eq "major tenth" }
    end
  end

  describe "predicate methods" do
    context "given a perfect unison" do
      let(:unison) { described_class.get(:perfect_unison) }

      specify { expect(unison).to be_perfect }
      specify { expect(unison).not_to be_major }
      specify { expect(unison).not_to be_minor }
      specify { expect(unison).not_to be_diminished }
      specify { expect(unison).not_to be_doubly_diminished }
      specify { expect(unison).not_to be_augmented }
      specify { expect(unison).not_to be_doubly_augmented }

      specify { expect(unison).to be_unison }
      specify { expect(unison).not_to be_second }
      specify { expect(unison).not_to be_third }
      specify { expect(unison).not_to be_fourth }
      specify { expect(unison).not_to be_fifth }
      specify { expect(unison).not_to be_sixth }
      specify { expect(unison).not_to be_seventh }
      specify { expect(unison).not_to be_octave }

      specify { expect(unison).not_to be_step }
      specify { expect(unison).not_to be_skip }
      specify { expect(unison).not_to be_leap }
      specify { expect(unison).not_to be_large_leap }
    end

    context "given a major third" do
      let(:maj3) { described_class.get(:major_third) }

      specify { expect(maj3).not_to be_perfect }
      specify { expect(maj3).to be_major }
      specify { expect(maj3).not_to be_minor }
      specify { expect(maj3).not_to be_diminished }
      specify { expect(maj3).not_to be_doubly_diminished }
      specify { expect(maj3).not_to be_augmented }
      specify { expect(maj3).not_to be_doubly_augmented }

      specify { expect(maj3).not_to be_unison }
      specify { expect(maj3).not_to be_second }
      specify { expect(maj3).to be_third }
      specify { expect(maj3).not_to be_fourth }
      specify { expect(maj3).not_to be_fifth }
      specify { expect(maj3).not_to be_sixth }
      specify { expect(maj3).not_to be_seventh }
      specify { expect(maj3).not_to be_octave }

      specify { expect(maj3).not_to be_step }
      specify { expect(maj3).to be_skip }
      specify { expect(maj3).to be_leap }
      specify { expect(maj3).not_to be_large_leap }
    end
  end

  describe "size comparison" do
    specify { expect(maj3).to be > min3 }
    specify { expect(min3).to be < maj3 }
    specify { expect(p5).to be > maj3 }
    specify { expect(aug4).to eq dim5 }
  end

  context "given two pitches comprising a simple interval" do
    subject(:simple_interval) { described_class.new("A4", "E5") }

    its(:name) { is_expected.to eq "perfect fifth" }
    its(:number) { is_expected.to eq 5 }
    its(:number_name) { is_expected.to eq "fifth" }
    its(:quality) { is_expected.to eq :perfect }
    its(:shorthand) { is_expected.to eq "P5" }
    it { is_expected.to be_simple }
    it { is_expected.not_to be_compound }
    # it { is_expected.to be_named_number }

    it { is_expected.not_to be_step }
    it { is_expected.not_to be_skip }
    it { is_expected.to be_leap }
    it { is_expected.to be_large_leap }

    its(:octaves) { is_expected.to eq 0 }
    its(:simple_semitones) { is_expected.to eq 7 }

    describe "simplification" do
      its(:simple_number) { is_expected.to eq simple_interval.number }
      its(:simple_name) { is_expected.to eq simple_interval.name }
    end

    describe "inversion" do
      its(:inversion) { is_expected.to eq "perfect fourth" }
    end

    its(:interval_class) { is_expected.to eq 5 }
    its(:interval_class_name) { is_expected.to eq "ic 5" }
  end

  context "given two pitches comprising an augmented octave" do
    subject(:augmented_octave) { described_class.new("A4", "A#5") }

    its(:simple_number_name) { is_expected.to eq "octave" }
    its(:quality_name) { is_expected.to eq "augmented" }

    its(:name) { is_expected.to eq "augmented octave" }
    its(:number) { is_expected.to eq 8 }
    its(:number_name) { is_expected.to eq "octave" }
    its(:quality) { is_expected.to eq :augmented }
    its(:shorthand) { is_expected.to eq "A8" }

    it { is_expected.to be_simple }
    it { is_expected.not_to be_compound }

    it { is_expected.not_to be_step }
    it { is_expected.not_to be_skip }
    it { is_expected.to be_leap }
    it { is_expected.to be_large_leap }

    describe "simplification" do
      its(:simple_number) { is_expected.to eq augmented_octave.number }
      its(:simple_name) { is_expected.to eq augmented_octave.name }
    end

    describe "inversion" do
      specify { expect(augmented_octave.inversion.name).to eq "diminished octave" }
    end
  end

  context "given a compound interval" do
    subject { described_class.new("E3", "C5") }

    its(:name) { is_expected.to eq "minor thirteenth" }
    its(:number) { is_expected.to eq 13 }
    its(:number_name) { is_expected.to eq "thirteenth" }
    its(:quality) { is_expected.to eq "minor" }
    its(:shorthand) { is_expected.to eq "m13" }
    it { is_expected.not_to be_simple }
    it { is_expected.to be_compound }
    it { is_expected.to be_imperfect_consonance }
    it { is_expected.to be_consonance }

    describe "simplification" do
      its(:simple_number) { is_expected.to eq 6 }
      its(:simple_name) { is_expected.to eq "minor sixth" }
      it { is_expected.not_to be_sixth }
      it { is_expected.to be_sixth_or_compound }
    end

    describe "inversion" do
      its(:inversion) { is_expected.to eq "major third" }
    end
  end

  describe "naming" do
    specify { expect(described_class.new("B2", "B4").number_name).to eq "fifteenth" }
    specify { expect(described_class.new("B2", "C#5").number_name).to eq "sixteenth" }
    specify { expect(described_class.new("B2", "D#5").number_name).to eq "seventeenth" }
    specify { expect(described_class.new("B2", "E5").number_name).to eq "18th" }

    specify { expect(described_class.new("B4", "B4").name).to eq "perfect unison" }
    specify { expect(described_class.new("B2", "B4").name).to eq "perfect fifteenth" }
    specify { expect(described_class.new("B2", "E5").name).to eq "two octaves and a perfect fourth" }
    specify { expect(described_class.new("B2", "B5").name).to eq "three octaves" }
    specify { expect(described_class.new("B2", "C6").name).to eq "three octaves and a minor second" }
    specify { expect(described_class.new("C3", "D#6").name).to eq "three octaves and an augmented second" }

    specify { expect(described_class.new("C#4", "Fb4").name).to eq "doubly diminished fourth" }
    specify { expect(described_class.new("Eb4", "A#4").name).to eq "doubly augmented fourth" }
    specify { expect(described_class.new("Cb4", "F#4").name).to eq "doubly augmented fourth" }

    specify { expect(described_class.new("C4", "Cb5").name).to eq "diminished octave" }
  end

  describe "consonance" do
    specify { expect(described_class.get(:minor_second).consonance).to be_harsh_dissonance }
    specify { expect(described_class.get(:major_second).consonance).to be_mild_dissonance }
    specify { expect(described_class.get(:minor_third).consonance).to be_imperfect_consonance }
    specify { expect(described_class.get(:major_third).consonance).to be_imperfect_consonance }
    specify { expect(described_class.get(:perfect_fourth).consonance).to be_perfect_consonance }
    specify { expect(described_class.get(:perfect_fourth).consonance(:two_part_harmony)).to be_dissonance }
    specify { expect(described_class.get(:perfect_eleventh).consonance(:two_part_harmony)).to be_dissonance }
    specify { expect(described_class.get(:augmented_fourth).consonance).to be_dissonance }
    specify { expect(described_class.get(:diminished_fifth).consonance).to be_dissonance }
    specify { expect(described_class.get(:perfect_fifth).consonance).to be_perfect_consonance }
    specify { expect(described_class.get(:minor_sixth).consonance).to be_imperfect_consonance }
    specify { expect(described_class.get(:major_sixth).consonance).to be_imperfect_consonance }
    specify { expect(described_class.get(:minor_seventh).consonance).to be_mild_dissonance }
    specify { expect(described_class.get(:major_seventh).consonance).to be_harsh_dissonance }
    specify { expect(described_class.get(:diminished_octave).consonance).to be_dissonance }
    specify { expect(described_class.get(:perfect_octave).consonance).to be_perfect_consonance }
  end

  describe "above" do
    specify { expect(described_class.get(:perfect_fifth).above("C4")).to eq "G4" }
    specify { expect(described_class.get(:major_third).above("A4")).to eq "C#5" }
    specify { expect(described_class.get(:perfect_octave).above("Bb4")).to eq "Bb5" }
  end

  describe "below" do
    specify { expect(described_class.get(:perfect_fifth).below("G4")).to eq "C4" }
    specify { expect(described_class.get(:major_third).below("C#5")).to eq "A4" }
    specify { expect(described_class.get(:perfect_octave).below("Bb4")).to eq "Bb3" }
  end

  describe "diatonic set theory" do
    specify { expect(described_class.get(:major_third).diatonic_generic_interval).to eq 2 }
    specify { expect(described_class.get(:major_third).specific_interval).to eq 4 }

    specify { expect(described_class.get(:augmented_fourth).diatonic_generic_interval).to eq 3 }
    specify { expect(described_class.get(:augmented_fourth).specific_interval).to eq 6 }

    specify { expect(described_class.get(:minor_sixth).diatonic_generic_interval).to eq 5 }
    specify { expect(described_class.get(:minor_sixth).specific_interval).to eq 8 }

    specify { expect(described_class.get(:minor_tenth).diatonic_generic_interval).to eq 2 }
    specify { expect(described_class.get(:minor_tenth).specific_interval).to eq 3 }
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
