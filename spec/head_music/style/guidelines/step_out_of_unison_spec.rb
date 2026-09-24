require "spec_helper"

describe HeadMusic::Style::Guidelines::StepOutOfUnison do
  subject { assess(described_class, counterpoint) }

  let(:flow) { HeadMusic::Content::Flow.new(key_signature: "D dorian") }
  let(:cantus_firmus_pitches) { %w[D4 C4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }
  let(:counterpoint) do
    flow.add_voice(role: :counterpoint).tap do |voice|
      counterpoint_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1:0", :whole, pitch)
      end
    end
  end

  before do
    flow.add_voice(role: :cantus_firmus).tap do |voice|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1:0", :whole, pitch)
      end
    end
  end

  context "with no notes" do
    let(:counterpoint_pitches) { [] }

    it { is_expected.to be_adherent }
  end

  context "with no unisons" do
    let(:counterpoint_pitches) { %w[D5 A4 C5 B4 D5 A4 E5 D5 A4 C5 D5] }

    it { is_expected.to be_adherent }
  end

  context "with a unison at the beginning" do
    context "and a skip outward" do
      let(:counterpoint_pitches) { %w[D4 A4 C5 B4 D5 A4 E5 D5 A4 C5 D5] }

      it { is_expected.to be_adherent }
    end

    context "and a step outward" do
      let(:counterpoint_pitches) { %w[D4 E4 C5 B4 D5 A4 E5 D5 A4 G4 C4] }

      it { is_expected.to be_adherent }
    end
  end

  context "when the first note is missing" do
    let(:counterpoint_pitches) { [nil] + %w[E4 C5 B4 D5 A4 E5 D5 A4 G4 C4] }

    it { is_expected.to be_adherent }
  end

  context "with a unison in the middle" do
    context "and a skip outward" do
      let(:counterpoint_pitches) { %w[A4 A4 C5 D4 B4 A4 E5 D5 A4 C5 D5] }

      its(:marks_count) { is_expected.to eq 1 }
    end

    context "and a step outward" do
      let(:counterpoint_pitches) { %w[A4 A4 C5 D4 E4 A4 E5 D5 A4 C5 D5] }

      it { is_expected.to be_adherent }
    end
  end

  context "with a unison tied over the bar line and left by leap" do
    subject(:guideline) { assess(described_class, voice) }

    let(:voice) do
      HeadMusic::Notation::ABC.parse(
        species_abc(source: "example", cantus_firmus: "D4|F4|E4|D4|]", counterpoint: "z2 A2|c2 F2-|F2 c2|d4|]")
      ).counterpoint_voice
    end

    it { is_expected.to be_adherent }
  end

  # Salzer and Schachter apply the rule to fifth species (p. 106); these
  # interior unisons quitted by leap are Fux's liberties.
  context "with Fux's fifth-species figures" do
    def unison_marks(figure)
      assess(described_class, fux_fifth_species_example(figure).counterpoint_voice).marks.map(&:code)
    end

    it "passes the opening unisons of figures 83 and 86b" do
      expect(%w[83 86b].map { |figure| unison_marks(figure) }).to all(be_empty)
    end

    {
      "82" => ["3:3:000 to 4:1:000", "4:2:000 to 5:2:000"],
      "84a" => ["8:2:000 to 9:3:000"],
      "85a" => ["3:2:000 to 4:2:000"],
      "86a" => ["8:2:000 to 9:2:000"]
    }.each do |figure, codes|
      it "keeps figure #{figure}'s interior unisons left by leap" do
        expect(unison_marks(figure)).to eq codes
      end
    end
  end
end
