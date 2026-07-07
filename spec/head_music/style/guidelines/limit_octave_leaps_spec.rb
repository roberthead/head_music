require "spec_helper"

describe HeadMusic::Style::Guidelines::LimitOctaveLeaps do
  subject { described_class.new(voice) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "C major") }
  let(:voice) { composition.add_voice(role: :counterpoint) }

  context "with no notes" do
    it { is_expected.to be_adherent }

    its(:message) { is_expected.to eq "Use a maximum of one octave leap." }
  end

  context "with no octave leaps" do
    before do
      %w[C D E G C5 B A B C5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end

  context "with one octave leap" do
    before do
      %w[C5 B C5 C D E G B C5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end

  context "with two octave leaps" do
    before do
      %w[C5 B C5 C D C C5 B G B C5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
  end

  context "when configured to allow more than one octave leap" do
    subject { described_class.new(voice, maximum_leaps: 2) }

    its(:message) { is_expected.to eq "Use a maximum of two octave leaps." }
  end
end
