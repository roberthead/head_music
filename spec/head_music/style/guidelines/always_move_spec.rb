require "spec_helper"

describe HeadMusic::Style::Guidelines::AlwaysMove do
  subject { assess(described_class, voice) }

  let(:voice) { HeadMusic::Content::Voice.new }

  it { expect(violation_text(described_class)).to eq "Always move to a different note." }

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "with one note" do
    before do
      voice.place("1:1", :whole, "C")
    end

    it { is_expected.to be_adherent }
  end

  context "with motion" do
    before do
      %w[C D E D C G3 A3 D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end

  context "with a repeated note" do
    before do
      %w[C D E E C G3 A3 D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
    it { expect(violation_text(described_class)).not_to be_empty }
    its(:marks_count) { is_expected.to eq 1 }
    its(:first_mark_code) { is_expected.to eq "3:1:000 to 5:1:000" }
  end

  context "with a suspension's resolution anticipated on beat two" do
    def counterpoint(abc)
      HeadMusic::Notation::ABC.parse(
        species_abc(source: "example", cantus_firmus: "D4|F4|E4|D4|]", counterpoint: abc)
      ).counterpoint_voice
    end

    context "when the resolution ties forward" do
      let(:voice) { counterpoint("z2 A2|B2 d2-|d c c2-|c2 ^c2|d4|]") }

      it { is_expected.to be_adherent }
    end

    context "when the resolution does not tie forward" do
      let(:voice) { counterpoint("z2 A2|B2 d2-|d c c2|B4|]") }

      it { is_expected.to be_adherent }
    end

    context "when a half is repeated instead" do
      let(:voice) { counterpoint("z2 A2|B2 d2-|d2 c2|c4|]") }

      its(:marks_count) { is_expected.to eq 1 }
    end

    context "when no suspension precedes it" do
      let(:voice) { counterpoint("z2 A2|B2 e2|d c c2|B4|]") }

      its(:marks_count) { is_expected.to eq 1 }
    end

    context "when the quarter is approached from below" do
      let(:voice) { counterpoint("z2 A2|c2 B2-|B c c2|A4|]") }

      its(:marks_count) { is_expected.to eq 1 }
    end

    context "when the quarter repeats from beat one to beat two" do
      let(:voice) { counterpoint("z2 A2|B2 d2|c c B2|A4|]") }

      its(:marks_count) { is_expected.to eq 1 }
    end
  end

  context "with Fux's anticipated resolutions" do
    ["86a", "87 upper counterpoint (scan only; no kern transcription)", "87a", "88b"].each do |figure|
      it "passes figure #{figure}" do
        expect(assess(described_class, fux_fifth_species_example(figure).counterpoint_voice)).to be_adherent
      end
    end

    it "keeps figure 85b's half repeated across the bar line" do
      marks = assess(described_class, fux_fifth_species_example("85b").counterpoint_voice).marks
      expect(marks.map(&:code)).to eq ["9:3:000 to 10:2:000"]
    end
  end
end
