require "spec_helper"

describe HeadMusic::Style::Guidelines::PrepareOctaveLeaps do
  subject { described_class.new(voice) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "C major") }
  let(:voice) { composition.add_voice(role: :counterpoint) }

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "with no octave leaps" do
    before do
      %w[C D E G C5 B A B C5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end

  context "when starting with an octave leap" do
    before do
      %w[C C5 B A G A F E D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end

  context "when ending with an octave leap" do
    before do
      %w[C E F G C5 C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.not_to be_adherent }
    its(:first_mark_code) { is_expected.to eq "5:1:000 to 7:1:000" }
  end

  context "with a properly prepared octave leap in the middle" do
    before do
      %w[C E D C C5 B G E D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end

  context "with an octave leap in the middle approached from outside" do
    before do
      %w[C B3 C C5 B G E D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.not_to be_adherent }
    its(:first_mark_code) { is_expected.to eq "2:1:000 to 5:1:000" }
  end

  context "with an octave leap in the middle exited outside" do
    before do
      %w[C D C C5 D5 B G E D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.not_to be_adherent }
    its(:first_mark_code) { is_expected.to eq "3:1:000 to 6:1:000" }
  end
end
