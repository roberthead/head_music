require "spec_helper"

describe HeadMusic::Style::Guidelines::SingableIntervals do
  subject { described_class.new(voice) }

  let(:composition) { HeadMusic::Content::Composition.new(name: "C Major", key_signature: "C Major") }
  let(:voice) { HeadMusic::Content::Voice.new(composition: composition) }

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "with one note" do
    before do
      voice.place("1:1", :whole, "C")
    end

    it { is_expected.to be_adherent }
    its(:marks) { are_expected.to be_empty }
  end

  context "with only permitted intervals" do
    before do
      %w[C E D G G F E D A G B C5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
    its(:marks) { are_expected.to be_empty }
  end

  context "with an octave leap" do
    before do
      %w[C D E C C5 B A F G E F D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
    its(:marks) { are_expected.to be_empty }
  end

  context "with an ascending minor sixth" do
    before do
      %w[C D E C5 B A G E F D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
    its(:marks) { are_expected.to be_empty }
  end

  context "with a descending minor sixth" do
    before do
      %w[C E G A B C5 E D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.not_to be_adherent }
    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
    its(:first_mark_code) { is_expected.to eq "6:1:000 to 8:1:000" }
  end

  context "with a major sixth" do
    before do
      %w[C D E D B A G E F D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
    its(:first_mark_code) { is_expected.to eq "4:1:000 to 6:1:000" }
  end

  context "with a tritone" do
    before do
      %w[C D E F B A B C5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
    its(:first_mark_code) { is_expected.to eq "4:1:000 to 6:1:000" }
  end

  describe "message" do
    it "lists the permitted intervals, noting the ascending-only minor sixth" do
      expect(described_class.new(voice).message).to eq "Use only P1, m2, M2, m3, M3, P4, P5, m6 (ascending), P8 in the melodic line."
    end

    context "when an interval is permitted descending only" do
      subject(:guideline) { described_class.new(voice, ascending: %w[P1 M2], descending: %w[P1 M2 m7]) }

      it "annotates it as descending" do
        expect(guideline.message).to include "m7 (descending)"
      end
    end
  end

  context "when configured to permit major sixths" do
    subject(:guideline) { described_class.new(voice, ascending: permitted_intervals, descending: permitted_intervals) }

    let(:permitted_intervals) { %w[P1 m2 M2 m3 M3 P4 P5 m6 M6 P8] }

    context "with a major sixth" do
      before do
        %w[C D E D B A G E F D C].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
      its(:marks) { are_expected.to be_empty }
    end

    context "with a descending minor sixth" do
      before do
        %w[C E G A B C5 E D C].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
      its(:marks) { are_expected.to be_empty }
    end

    context "with a minor seventh" do
      before do
        %w[C E G F G3 A3 B3 C].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
    end

    describe "message" do
      it "lists the configured intervals" do
        expect(guideline.message).to eq "Use only P1, m2, M2, m3, M3, P4, P5, m6, M6, P8 in the melodic line."
      end
    end
  end
end
