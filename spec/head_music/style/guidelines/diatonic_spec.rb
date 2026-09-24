require "spec_helper"

describe HeadMusic::Style::Guidelines::Diatonic do
  subject(:guideline) { assess(described_class, voice) }

  let(:flow) { HeadMusic::Content::Flow.new(key_signature: "D dorian") }
  let(:voice) { flow.add_voice }

  it { expect(violation_text(described_class)).not_to be_empty }

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

  describe "the accidentals the modes require" do
    def line(key, pitches)
      HeadMusic::Content::Flow.new(key_signature: key).add_voice.tap do |line_voice|
        pitches.each.with_index(1) { |pitch, bar| line_voice.place("#{bar}:1", :whole, pitch) }
      end
    end

    def marks_on(key, pitches)
      assess(described_class, line(key, pitches)).marks_count
    end

    it "passes a raised seventh stepping up to the tonic mid-line" do
      expect(marks_on("G mixolydian", %w[G4 A4 F#4 G4 B4 A4 G4])).to eq 0
    end

    it "marks a raised seventh that does not step to the tonic" do
      expect(marks_on("G mixolydian", %w[G4 A4 F#4 E4 F4 A4 G4])).to eq 1
    end

    it "passes a raised sixth before a raised seventh in aeolian" do
      expect(marks_on("A aeolian", %w[A4 E4 F#4 G#4 A4])).to eq 0
    end

    it "marks a raised sixth that does not rise to a raised seventh" do
      expect(marks_on("A aeolian", %w[A4 E4 F#4 E4 A4])).to eq 1
    end

    it "marks a raised sixth and seventh that do not reach the tonic" do
      expect(marks_on("A aeolian", %w[A4 E4 F#4 G#4 E4 A4])).to eq 2
    end

    it "passes the lydian lowered fourth" do
      expect(marks_on("F lydian", %w[F4 A4 Bb4 A4 G4 F4])).to eq 0
    end

    it "passes the dorian lowered sixth in descent" do
      expect(marks_on("D dorian", %w[D4 C5 Bb4 G4 A4 D4])).to eq 0
    end

    it "marks the dorian lowered sixth in ascent" do
      expect(marks_on("D dorian", %w[D4 G4 Bb4 C5 A4 D4])).to eq 1
    end

    it "passes the mixolydian lowered third in descent" do
      expect(marks_on("G mixolydian", %w[G4 C5 Bb4 A4 G4])).to eq 0
    end

    it "marks a phrygian lowered fifth" do
      expect(marks_on("E phrygian", %w[E4 C5 Bb4 A4 E4])).to eq 1
    end
  end

  context "with Fux's fifth-species figures that use the modal accidentals" do
    %w[82 85a 85b 86a].each do |figure|
      it "passes figure #{figure}" do
        expect(assess(described_class, fux_fifth_species_example(figure).counterpoint_voice)).to be_adherent
      end
    end
  end

  context "with the cantus firmus Fux D with chromatic notes added" do
    let(:voice) do
      fux_cantus_firmus_examples_with_errors
        .detect { |example| example.flow.name == "Fux D with chromatic notes added" }
        .cantus_firmus_voice
    end

    its(:marks_count) { is_expected.to eq 3 }
  end
end
