require "spec_helper"

describe HeadMusic::Style::Guidelines::MinimumNotes do
  subject { assess(described_class, voice, minimum: minimum) }

  let(:flow) { HeadMusic::Content::Flow.new(key_signature: "D dorian") }
  let(:voice) { HeadMusic::Content::Voice.new(flow: flow, role: "Cantus Firmus") }
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

    it { is_expected.to be_a HeadMusic::Style::GuideItem }
    its(:guideline) { is_expected.to eq described_class }
    its(:config) { is_expected.to eq(minimum: 8) }

    it "builds a guide item that reports the configured minimum" do
      voice = HeadMusic::Content::Voice.new
      expect(configured.assess(voice, :primary).message).to eq "Write at least eight notes."
    end
  end
end
