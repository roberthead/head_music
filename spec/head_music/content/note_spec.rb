require "spec_helper"

describe HeadMusic::Content::Note do
  subject(:note) { described_class.new("F#5", :quarter) }

  its(:pitch) { is_expected.to eq "F#5" }
  its(:rhythmic_duration) { is_expected.to be_a(HeadMusic::Rudiment::RhythmicDuration) }
  its(:voice) { is_expected.to be_a(HeadMusic::Content::Voice) }
  its(:position) { is_expected.to be_a(HeadMusic::Content::Position) }
  its(:to_s) { is_expected.to eq "F♯5 at 1:1:000" }

  it "raises for a rhythmic duration it cannot read" do
    expect { described_class.new("F#5", "garbage") }.to raise_error(ArgumentError, /unknown rhythmic duration/)
  end

  describe "#method_missing" do
    it { is_expected.to be_note }
    it { is_expected.not_to be_rest }

    it "responds only to voice event methods" do
      expect {
        note.foo
      }.to raise_error(NoMethodError, /undefined method [`']foo'/)
    end
  end
end
