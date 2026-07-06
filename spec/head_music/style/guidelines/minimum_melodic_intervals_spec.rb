require "spec_helper"

describe HeadMusic::Style::Guidelines::MinimumMelodicIntervals do
  subject { described_class.new(voice, minimum: minimum) }

  let(:composition) { HeadMusic::Notation::ABC.parse(abc) }
  let(:voice) { composition.voices.first }
  let(:minimum) { 2 }

  let(:abc) do
    <<~ABC
      X:1
      T:Fixture
      M:4/4
      L:1/4
      K:C
      #{melody}
    ABC
  end

  context "with sufficient melodic motion" do
    let(:melody) { "C D E F|" }

    it { is_expected.to be_adherent }
    its(:fitness) { is_expected.to eq 1 }
  end

  context "with too little melodic motion" do
    let(:melody) { "C C C D|" }

    its(:fitness) { is_expected.to eq 0.5 }
    its(:message) { is_expected.to eq "Write at least two melodic intervals." }
  end

  context "with an all-repeated-note line" do
    let(:melody) { "C C C C|" }

    its(:fitness) { is_expected.to eq 0 }
    its(:marks_count) { is_expected.to eq 1 }
  end

  context "with no notes" do
    let(:voice) { HeadMusic::Content::Voice.new }

    its(:fitness) { is_expected.to eq 0 }
    its(:marks_count) { is_expected.to eq 1 }
    its(:first_mark_code) { is_expected.to eq "1:1:000 to 2:1:000" }
  end

  describe "#gate?" do
    let(:melody) { "C D E F|" }

    it("is a gate by default") { is_expected.to be_gate }
  end

  describe ".with" do
    subject(:configured) { described_class.with(3) }

    it { is_expected.to be_a HeadMusic::Style::Annotation::Configured }
    its(:guideline_class) { is_expected.to eq described_class }
    its(:options) { is_expected.to eq(minimum: 3) }

    it "builds an annotation that reports the configured minimum" do
      voice = HeadMusic::Content::Voice.new
      expect(configured.new(voice).message).to eq "Write at least three melodic intervals."
    end

    context "with an inline gate override" do
      subject(:configured) { described_class.with(3, gate: false) }

      it "builds an annotation that is not a gate and reports the configured minimum" do
        annotation = configured.new(HeadMusic::Content::Voice.new)
        expect(annotation.gate?).to be false
        expect(annotation.message).to eq "Write at least three melodic intervals."
      end
    end
  end
end
