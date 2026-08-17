require "spec_helper"

describe HeadMusic::Style::Guidelines::SetAgainstAnotherVoice do
  subject { assess(described_class, counterpoint) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:cantus_firmus) { composition.add_voice(role: :cantus_firmus) }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }

  its(:message) { is_expected.not_to be_empty }

  context "when a companion voice sounds" do
    before do
      %w[D4 F4 E4 D4].each_with_index { |pitch, bar| cantus_firmus.place("#{bar + 1}:1", :whole, pitch) }
      %w[A4 A4 G4 A4].each_with_index { |pitch, bar| counterpoint.place("#{bar + 1}:1", :whole, pitch) }
    end

    it { is_expected.to be_adherent }
    its(:marks) { is_expected.to be_empty }
  end

  context "when the companion voice exists but has no notes" do
    before do
      cantus_firmus
      %w[A4 A4 G4 A4].each_with_index { |pitch, bar| counterpoint.place("#{bar + 1}:1", :whole, pitch) }
    end

    it { is_expected.not_to be_adherent }
    its(:fitness) { is_expected.to eq 0 }
  end

  context "when there is no companion voice at all" do
    subject { assess(described_class, solo) }

    let(:solo_composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
    let(:solo) { solo_composition.add_voice(role: :counterpoint) }

    before { %w[A4 A4 G4 A4].each_with_index { |pitch, bar| solo.place("#{bar + 1}:1", :whole, pitch) } }

    it { is_expected.not_to be_adherent }
    its(:fitness) { is_expected.to eq 0 }

    it "does not raise reaching for the companion that is not there" do
      expect { assess(described_class, solo).fitness }.not_to raise_error
    end
  end

  # The branch exists because Mark.for_all([]) returns no marks, and no marks
  # means a fitness of 1.0 -- so without it this gate would pass on exactly the
  # input it exists to catch.
  context "when the voice itself is empty and has no companion" do
    subject { assess(described_class, empty) }

    let(:empty_composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
    let(:empty) { empty_composition.add_voice(role: :counterpoint) }

    it { is_expected.not_to be_adherent }
    its(:fitness) { is_expected.to eq 0 }
    its(:marks) { is_expected.not_to be_empty }
  end
end
