# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Style::Guidelines::ConsonantClimax do
  subject { described_class.new(voice) }

  let(:voice) { HeadMusic::Voice.new }

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "when the high note occurs once" do
    context "when on the 3rd scale degree" do
      before do
        %w[C D E D C G3 A3 D C].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
    end

    context "when on the 7th scale degree" do
      before do
        %w[C D E G B G F E D C].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
    end
  end

  context "when the high note occurs twice" do
    context "when on the 3rd scale degree" do
      context "with one step between" do
        before do
          %w[C D E D E C G3 A3 D C].each.with_index(1) do |pitch, bar|
            voice.place("#{bar}:1", :whole, pitch)
          end
        end

        it { is_expected.to be_adherent }
      end

      context "with one skip between" do
        before do
          %w[C D E C E C G3 A3 B3 C].each.with_index(1) do |pitch, bar|
            voice.place("#{bar}:1", :whole, pitch)
          end
        end

        its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
      end

      context "with more than one note between" do
        before do
          %w[C D E D C E D G3 A3 D C].each.with_index(1) do |pitch, bar|
            voice.place("#{bar}:1", :whole, pitch)
          end
        end

        its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
      end
    end

    context "when on the 7th scale degree" do
      before do
        %w[C D E G B A B G E D C].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < HeadMusic::PENALTY_FACTOR }
    end
  end

  context "when the high note occurs three times" do
    before do
      %w[C D E D C E D E D G3 A3 D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < HeadMusic::PENALTY_FACTOR }
  end
end
