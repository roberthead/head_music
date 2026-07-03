require "spec_helper"

describe HeadMusic::Style::Guidelines::MaximumNotes do
  subject { described_class.new(voice, maximum: maximum) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:voice) { HeadMusic::Content::Voice.new(composition: composition, role: "Cantus Firmus") }
  let(:maximum) { 5 }

  context "with more than the configured maximum" do
    before do
      %w[D E F G A B].each.with_index(1) { |pitch, bar| voice.place("#{bar}:1", :whole, pitch) }
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:fitness) { is_expected.to be > 0 }
    its(:marks_count) { is_expected.to eq 1 }
    its(:message) { is_expected.to eq "Write up to five notes." }
  end

  context "with exactly the configured maximum" do
    before do
      %w[D E F G A].each.with_index(1) { |pitch, bar| voice.place("#{bar}:1", :whole, pitch) }
    end

    it { is_expected.to be_adherent }
  end

  context "when instantiated without an option (subclass default)" do
    subject { HeadMusic::Style::Guidelines::UpToFourteenNotes.new(voice) }

    its(:message) { is_expected.to eq "Write up to fourteen notes." }
  end
end
