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

  context "when instantiated without an option (subclass default)" do
    subject { HeadMusic::Style::Guidelines::AtLeastEightNotes.new(voice) }

    its(:message) { is_expected.to eq "Write at least eight notes." }
  end
end
