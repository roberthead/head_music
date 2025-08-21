require "spec_helper"

describe HeadMusic::Rudiment::Tempo do
  describe "#initialize" do
    subject(:tempo) { described_class.new(beat_value, beats_per_minute) }

    context "with q = 120" do
      let(:beat_value) { "quarter" }
      let(:beats_per_minute) { 120 }

      its(:beat_value) { is_expected.to eq "quarter" }
      its(:beats_per_minute) { is_expected.to eq 120 }
      its(:beat_duration_in_seconds) { is_expected.to eq 0.5 }
      its(:beat_duration_in_nanoseconds) { is_expected.to eq 500_000_000 }
      its(:ticks_per_beat) { is_expected.to eq 960 }
    end

    context "with e = 140" do
      let(:beat_value) { "eighth" }
      let(:beats_per_minute) { 140 }

      its(:beat_value) { is_expected.to eq "eighth" }
      its(:beats_per_minute) { is_expected.to eq 140 }
      its(:beat_duration_in_seconds) { is_expected.to be_within(0.00001).of(0.42857) }
      its(:beat_duration_in_nanoseconds) { is_expected.to be_within(1).of(428571428) }
      its(:ticks_per_beat) { is_expected.to eq 480 }
    end

    context "with q. = 92" do
      let(:beat_value) { "dotted quarter" }
      let(:beats_per_minute) { 92 }

      its(:beat_value) { is_expected.to eq "dotted quarter" }
      its(:beats_per_minute) { is_expected.to eq 92 }
      its(:beat_duration_in_seconds) { is_expected.to eq(0.6521739130434783) }
      its(:beat_duration_in_nanoseconds) { is_expected.to be_within(1).of(652173913) }
      its(:ticks_per_beat) { is_expected.to eq 1440 }
    end
  end
end
