require "spec_helper"

describe HeadMusic::Style::Guidelines::MinimumNotes do
  subject { described_class.new(voice, minimum: minimum) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:voice) { HeadMusic::Content::Voice.new(composition: composition, role: "Cantus Firmus") }
  let(:minimum) { 5 }

  context "with fewer than the configured minimum" do
    before do
      %w[D E F G].each.with_index(1) { |pitch, bar| voice.place("#{bar}:1", :whole, pitch) }
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:fitness) { is_expected.to be > 0 }
    its(:message) { is_expected.to eq "Write at least five notes." }
  end

  context "with exactly the configured minimum" do
    before do
      %w[D E F G A].each.with_index(1) { |pitch, bar| voice.place("#{bar}:1", :whole, pitch) }
    end

    it { is_expected.to be_adherent }
  end

  context "with no notes" do
    let(:voice) { HeadMusic::Content::Voice.new }
    let(:minimum) { 8 }

    its(:fitness) { is_expected.to be < 0.1 }
    its(:marks_count) { is_expected.to eq 1 }
    its(:first_mark_code) { is_expected.to eq "1:1:000 to 2:1:000" }
  end

  describe ".with" do
    subject(:configured) { described_class.with(8) }

    it { is_expected.to be_a HeadMusic::Style::Annotation::Configured }
    its(:guideline_class) { is_expected.to eq described_class }
    its(:options) { is_expected.to eq(minimum: 8) }

    it "builds an annotation that reports the configured minimum" do
      voice = HeadMusic::Content::Voice.new
      expect(configured.new(voice).message).to eq "Write at least eight notes."
    end
  end
end
