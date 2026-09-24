require "spec_helper"

describe HeadMusic::Style::Guidelines::MixSpeciesTextures do
  subject(:guideline) { assess(described_class, voice) }

  let(:voice) { counterpoint_over(abc) }

  def counterpoint_over(abc)
    HeadMusic::Notation::ABC.parse(
      species_abc(source: "example", cantus_firmus: "D4|F4|E4|D4|G4|F4|A4|G4|]", counterpoint: abc)
    ).counterpoint_voice
  end

  def marked_bars
    guideline.marks.map { |mark| mark.start_position.bar_number }.uniq
  end

  context "with no notes" do
    let(:voice) { HeadMusic::Content::Flow.new.add_voice(role: :counterpoint) }

    it { is_expected.to be_adherent }
  end

  context "with a one-bar voice" do
    let(:abc) { "d4|]" }

    it { is_expected.to be_adherent }
  end

  context "with every Fux fifth-species figure" do
    it "finds no run longer than two bars" do
      fux_fifth_species_examples.each do |example|
        expect(assess(described_class, example.counterpoint_voice)).to be_adherent, example.source
      end
    end
  end

  context "with Fux's fourth-species figure 73" do
    let(:voice) { fux_fourth_species_examples.first.counterpoint_voice }

    it "marks the two runs of ligatures on either side of the untied bar" do
      expect(marked_bars).to eq [2, 3, 4, 5, 7, 8, 9, 10]
    end
  end

  context "with Fux's third-species figure 55" do
    let(:voice) { fux_third_species_examples.first.counterpoint_voice }

    it "marks every bar but the last" do
      expect(marked_bars).to eq (1..10).to_a
    end
  end

  context "with the triple-meter third-species line" do
    let(:voice) { third_species_triple_meter_examples.first.counterpoint_voice }

    it "marks every bar but the last" do
      expect(marked_bars).to eq (1..10).to_a
    end
  end

  context "with a first-species line" do
    let(:abc) { "A4|A4|G4|A4|B4|c4|B4|A4|]" }

    it "marks every bar but the last" do
      expect(marked_bars).to eq (1..7).to_a
    end

    it "costs a penalty factor for each marked bar" do
      expect(guideline.fitness).to be_within(0.001).of(HeadMusic::PENALTY_FACTOR**7)
    end
  end

  context "with a whole note held across the bar line" do
    let(:abc) { "A4|d4-|d4|c2 B2|A B c d|e2 d2-|d c B A|B4|]" }

    it "counts the held bar as a whole-note bar" do
      expect(marked_bars).to eq [1, 2, 3]
    end
  end

  context "with a run of exactly two bars in one texture" do
    let(:abc) { "A2 d2|c2 B2|A B c d|e2 d2-|d c B A|B2 c2|B G A B|A4|]" }

    it { is_expected.to be_adherent }
  end

  context "with a run of three bars in one texture" do
    let(:abc) { "A2 d2|c2 B2|A2 G2|A B c d|e2 d2-|d c B A|B G A B|A4|]" }

    it "marks all three bars" do
      expect(marked_bars).to eq [1, 2, 3]
    end
  end

  context "with two runs of two separated by a florid bar" do
    let(:abc) { "A2 d2|c2 B2|A2 G A|B2 d2|c2 B2|A B c d|e d c B|A4|]" }

    it { is_expected.to be_adherent }
  end

  context "with a bar entered by a tie and followed by quarters" do
    let(:abc) { "A B c d|e d c B-|B A G A|B2 c2|d2 c2|B c d e|d c B c|d4|]" }

    it "counts the bar as florid, ending the run of quarters" do
      expect(guideline).to be_adherent
    end
  end

  context "with a dotted half" do
    let(:abc) { "A2 d2|c2 B2|A3 G|A2 B2|c2 d2|e d c B|A B c d|e4|]" }

    it "counts the bar as florid" do
      expect(guideline).to be_adherent
    end
  end

  context "with an empty bar in the middle of a run" do
    let(:abc) { "A2 d2|c2 B2|z4|A2 G2|A2 B2|c d e d|c B A B|c4|]" }

    it "ends the run without counting toward one" do
      expect(guideline).to be_adherent
    end
  end

  context "with a solo voice" do
    let(:voice) do
      HeadMusic::Content::Flow.new.add_voice.tap do |solo|
        %w[C4 D4 E4 F4 G4].each.with_index(1) { |pitch, bar| solo.place("#{bar}:1", :whole, pitch) }
      end
    end

    it "is judged over the voice's own bars" do
      expect(marked_bars).to eq [1, 2, 3, 4]
    end
  end

  context "with a configured run limit" do
    subject(:guideline) { assess(described_class, voice, maximum_run: 3) }

    let(:abc) { "A2 d2|c2 B2|A2 G2|A B c d|e2 d2-|d c B A|B G A B|A4|]" }

    it { is_expected.to be_adherent }
  end
end
