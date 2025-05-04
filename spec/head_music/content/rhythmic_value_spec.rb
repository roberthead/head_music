require "spec_helper"

describe HeadMusic::Content::RhythmicValue do
  describe "constructors" do
    context "when passed as a string" do
      subject(:value) { described_class.get(argument) }

      context "when a sixteenth" do
        let(:argument) { "sixteenth" }

        it { is_expected.to eq :sixteenth }

        its(:ticks) { are_expected.to eq 240 }
        its(:per_whole) { is_expected.to eq 16 }
      end

      context "when a thirty-second" do
        let(:argument) { "thirty-second" }

        it { is_expected.to eq :"thirty-second" }

        its(:ticks) { are_expected.to eq 120 }
        its(:per_whole) { is_expected.to eq 32 }
        its(:name_modifier_prefix) { is_expected.to be_nil }
      end

      context "with a dot" do
        let(:argument) { "dotted eighth" }

        its(:ticks) { are_expected.to eq 720 }
        its(:per_whole) { is_expected.to eq(16 / 3.0) }
        its(:name_modifier_prefix) { is_expected.to eq "dotted" }
      end

      context "with two dots" do
        let(:argument) { "double-dotted eighth" }

        its(:ticks) { are_expected.to eq 840 }
        its(:name_modifier_prefix) { is_expected.to eq "double-dotted" }
      end

      context "with three dots" do
        let(:argument) { "triple-dotted eighth" }

        its(:ticks) { are_expected.to eq 900 }
        its(:name_modifier_prefix) { is_expected.to eq "triple-dotted" }
      end
    end

    context "when passed a unit and dots" do
      subject(:value) { described_class.new(unit, dots: dots) }

      let(:dots) { nil }

      context "with no dots" do
        subject(:value) { described_class.get(unit) }

        let(:unit) { HeadMusic::Rudiment::RhythmicUnit.get(:quarter) }

        its(:name) { is_expected.to eq "quarter" }
        its(:ticks) { are_expected.to eq 960 }
        its(:relative_value) { is_expected.to eq 1.0 / 4 }
        its(:total_value) { is_expected.to eq 1.0 / 4 }
      end

      context "for a dotted half" do
        let(:unit) { HeadMusic::Rudiment::RhythmicUnit.get(:half) }
        let(:dots) { 1 }

        its(:name) { is_expected.to eq "dotted half" }
        its(:ticks) { are_expected.to eq 960 * 3 }
        its(:relative_value) { is_expected.to eq 3.0 / 4 }
        its(:total_value) { is_expected.to eq 3.0 / 4 }
      end

      context "for a dotted quarter" do
        let(:unit) { HeadMusic::Rudiment::RhythmicUnit.get(:quarter) }
        let(:dots) { 1 }

        its(:name) { is_expected.to eq "dotted quarter" }
        its(:ticks) { are_expected.to eq 1440 }
        its(:relative_value) { is_expected.to eq 1.5 / 4 }
        its(:total_value) { is_expected.to eq 1.5 / 4 }
      end

      context "for a sixteenth" do
        let(:unit) { HeadMusic::Rudiment::RhythmicUnit.get(:sixteenth) }

        its(:name) { is_expected.to eq "sixteenth" }
        its(:ticks) { are_expected.to eq 240 }
        its(:relative_value) { is_expected.to eq 1.0 / 16 }
        its(:total_value) { is_expected.to eq 1.0 / 16 }
      end

      context "for a triple-dotted half" do
        let(:unit) { HeadMusic::Rudiment::RhythmicUnit.get(:half) }
        let(:dots) { 3 }

        its(:name) { is_expected.to eq "triple-dotted half" }
        its(:ticks) { are_expected.to eq 3600 }
        its(:relative_value) { is_expected.to eq(0.5 + 0.25 + 0.125 + 0.0625) }
        its(:total_value) { is_expected.to eq(0.5 + 0.5 / 2 + 0.5 / 4 + 0.5 / 8) }
      end
    end

    context "when passed a second tied value" do
      context "for an eighth tied to a dotted quarter" do
        subject(:value) { described_class.new(:eighth, tied_value: second_value) }

        let(:second_value) { described_class.new(:quarter, dots: 1) }

        its(:name) { is_expected.to eq "eighth tied to dotted quarter" }
        its(:ticks) { are_expected.to eq 1920 }
        its(:relative_value) { is_expected.to eq 0.125 }
        its(:total_value) { is_expected.to eq 0.5 }
      end

      context "for a half tied to a quarter tied to an eighth" do
        subject(:value) { described_class.new(:half, tied_value: second_value) }

        let(:second_value) { described_class.new(:quarter, tied_value: third_value) }
        let(:third_value) { described_class.new(:eighth) }

        its(:name) { is_expected.to eq "half tied to quarter tied to eighth" }
        its(:ticks) { are_expected.to eq 960 * 4 * 7.0 / 8 }
        its(:relative_value) { is_expected.to eq 0.5 }
        its(:total_value) { is_expected.to eq 7.0 / 8 }
      end
    end
  end
end
