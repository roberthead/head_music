require "spec_helper"

describe HeadMusic::Style::Guidelines::SingleLargeLeaps do
  subject { described_class.new(voice) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:voice) { HeadMusic::Content::Voice.new(composition: composition) }

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "with leaps" do
    context "when recovered by step in the opposite direction" do
      before do
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
    end

    context "when followed by skip in the opposite direction" do
      before do
        %w[D4 F4 E4 D4 G4 E4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
    end

    context "when followed by large leap in the opposite direction" do
      before do
        %w[D4 F4 E4 D4 G4 D4 E4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
    end

    context "when followed by leap in the same direction" do
      before do
        %w[D4 A4 C#5 D5].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
    end

    context "when followed by step in same direction" do
      before do
        %w[D4 F4 E4 D4 G4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
    end

    context "when not recovered, but spelling a triad" do
      before do
        %w[D4 F4 E4 D4 G4 B4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
    end

    context "when recovered by skip spelling a triad" do
      let(:composition) { HeadMusic::Content::Composition.new(key_signature: "F lydian") }

      before do
        # FUX example
        %w[F4 G4 A4 F4 D4 E4 F4 C5 A4 F4 G4 F4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
      its(:first_mark_code) { is_expected.to be_nil }
    end
  end
end
