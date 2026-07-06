require "spec_helper"

describe HeadMusic::Style::Guidelines::MaximumNotes do
  subject(:guideline) { described_class.new(voice, maximum: maximum) }

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
    its(:first_mark_code) { is_expected.to eq "6:1:000 to 7:1:000" }
    its(:message) { is_expected.to eq "Write up to five notes." }

    it "scores the overage rate of one note beyond the maximum among six" do
      expect(guideline.fitness).to be_within(1e-9).of(HeadMusic::PENALTY_FACTOR**(1.0 / 6))
    end
  end

  describe "rate invariance" do
    context "with two overage notes among twelve" do
      let(:maximum) { 10 }

      before do
        %w[D4 E4 F4 G4 A4 B4 C5 D5 E5 F5 G5 A5].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      its(:marks_count) { is_expected.to eq 2 }

      it "scores the same rate as one overage note among six" do
        expect(guideline.fitness).to be_within(1e-9).of(HeadMusic::PENALTY_FACTOR**(1.0 / 6))
      end
    end
  end

  context "with exactly the configured maximum" do
    before do
      %w[D E F G A].each.with_index(1) { |pitch, bar| voice.place("#{bar}:1", :whole, pitch) }
    end

    it { is_expected.to be_adherent }
  end

  describe ".with" do
    subject(:configured) { described_class.with(14) }

    it { is_expected.to be_a HeadMusic::Style::Annotation::Configured }
    its(:guideline_class) { is_expected.to eq described_class }
    its(:options) { is_expected.to eq(maximum: 14) }

    it "builds an annotation that reports the configured maximum" do
      voice = HeadMusic::Content::Voice.new
      expect(configured.new(voice).message).to eq "Write up to fourteen notes."
    end

    context "with an inline weight override" do
      subject(:configured) { described_class.with(14, weight: 2.0) }

      it "builds an annotation with the overridden weight and configured maximum" do
        annotation = configured.new(HeadMusic::Content::Voice.new)
        expect(annotation.weight).to eq 2.0
        expect(annotation.message).to eq "Write up to fourteen notes."
      end
    end
  end
end
