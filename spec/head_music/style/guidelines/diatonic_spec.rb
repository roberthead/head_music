require "spec_helper"

describe HeadMusic::Style::Guidelines::Diatonic do
  subject(:guideline) { described_class.new(voice) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:voice) { composition.add_voice }

  its(:message) { is_expected.not_to be_empty }

  context "when there are no notes" do
    it { is_expected.to be_adherent }
    its(:marks_count) { is_expected.to eq 0 }
  end

  context "when the notes are in the key" do
    before do
      %w[D4 E4 F4 G4 A4 B4 G4 B4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
    its(:marks_count) { is_expected.to eq 0 }
  end

  context "when a note is not in the key" do
    before do
      %w[D4 E4 F#4 G4 A4 B4 G4 B4 A4 G4 F#4 E4 D4].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:fitness) { is_expected.to be > 0 }
    its(:marks_count) { is_expected.to eq 2 }

    it "scores the violation rate of two out-of-key notes among thirteen" do
      expect(guideline.fitness).to be_within(1e-9).of(HeadMusic::PENALTY_FACTOR**(2.0 / 13))
    end
  end

  describe "rate invariance" do
    context "with one out-of-key note among five notes" do
      before do
        %w[D4 E4 F#4 G4 A4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      its(:marks_count) { is_expected.to eq 1 }

      it "scores the same rate as two violations among ten notes" do
        expect(guideline.fitness).to be_within(1e-9).of(HeadMusic::PENALTY_FACTOR**0.2)
      end
    end

    context "with two out-of-key notes among ten notes" do
      before do
        %w[D4 E4 F#4 G4 A4 B4 G#4 A4 G4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      its(:marks_count) { is_expected.to eq 2 }

      it "scores the same rate as one violation among five notes" do
        expect(guideline.fitness).to be_within(1e-9).of(HeadMusic::PENALTY_FACTOR**0.2)
      end
    end
  end

  context "with a raised leading tone in the cadence" do
    before do
      %w[D E F D B3 C D B3 C D A3 B3 C# D].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end
end
