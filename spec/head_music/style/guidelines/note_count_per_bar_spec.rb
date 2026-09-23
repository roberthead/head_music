require "spec_helper"

describe HeadMusic::Style::Guidelines::NoteCountPerBar do
  subject(:guideline) { assess(described_class, counterpoint, count: count, rhythmic_value: rhythmic_value) }

  let(:flow) { HeadMusic::Content::Flow.new(key_signature: "D dorian") }
  let(:counterpoint) { flow.add_voice(role: :counterpoint) }
  let(:count) { 1 }
  let(:rhythmic_value) { :whole }
  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4] }

  before do
    flow.add_voice(role: :cantus_firmus).tap do |voice|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end
  end

  context "without a cantus firmus voice" do
    let(:solo_flow) { HeadMusic::Content::Flow.new(key_signature: "D dorian") }
    let(:counterpoint) { solo_flow.add_voice(role: :counterpoint) }

    before do
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :half, "A4")
      counterpoint.place("2:3", :half, "C5")
      counterpoint.place("3:1", :whole, "B4")
    end

    it { is_expected.not_to be_adherent }

    it "marks the solo voice's own middle bar" do
      expect(guideline.marks.map(&:code)).to eq ["2:1:000 to 3:1:000"]
    end
  end

  context "with no notes" do
    it { is_expected.to be_adherent }

    it "returns no marks" do
      expect(guideline.marks).to eq []
    end
  end

  context "with notes in two or fewer bars (no middle bars)" do
    before do
      counterpoint.place("1:1", :half, "A4")
      counterpoint.place("2:1", :half, "A4")
    end

    it { is_expected.to be_adherent }

    it "returns no marks" do
      expect(guideline.marks).to eq []
    end
  end

  context "when the voice starts after the cantus firmus" do
    before do
      # Bars 2 and 5 are the voice's own first and last bars, so only bars 3
      # and 4 are judged; bar 1 is not an empty middle bar.
      counterpoint.place("2:1", :whole, "A4")
      counterpoint.place("3:1", :whole, "A4")
      counterpoint.place("4:1", :half, "B4")
      counterpoint.place("4:3", :half, "C5")
      counterpoint.place("5:1", :whole, "D5")
    end

    it "judges only the bars between the voice's first and last" do
      expect(guideline.marks.map(&:code)).to eq ["4:1:000 to 5:1:000"]
    end
  end

  context "when the voice ends before the cantus firmus" do
    before do
      # The voice's last bar is 3, so bars 4 and 5 are not empty middle bars.
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :whole, "A4")
      counterpoint.place("3:1", :whole, "B4")
    end

    it { is_expected.to be_adherent }
  end

  context "with the correct note in each middle bar" do
    before do
      %w[A4 A4 C5 B4 D5].each.with_index(1) do |pitch, bar|
        counterpoint.place("#{bar}:1", :whole, pitch)
      end
    end

    it { is_expected.to be_adherent }
  end

  context "with the wrong notes in a middle bar" do
    before do
      # Middle bar 2 has two half notes instead of the required single whole
      # note, so its placements are marked.
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :half, "A4")
      counterpoint.place("2:3", :half, "C5")
      counterpoint.place("3:1", :whole, "B4")
      counterpoint.place("4:1", :whole, "A4")
      counterpoint.place("5:1", :whole, "D5")
    end

    it { is_expected.not_to be_adherent }

    it "marks the offending bar" do
      expect(guideline.marks).not_to be_empty
    end
  end

  context "with an empty middle bar" do
    before do
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :whole, "A4")
      counterpoint.place("4:1", :whole, "B4")
    end

    it { is_expected.not_to be_adherent }

    it "marks the span of the empty bar with no placements" do
      mark = guideline.marks.first
      expect(guideline.marks.length).to eq 1
      expect(mark.code).to eq "3:1:000 to 4:1:000"
      expect(mark.placements).to be_empty
    end
  end

  describe "#message" do
    before do
      counterpoint.place("1:1", :whole, "A4")
      counterpoint.place("2:1", :quarter, "A4")
      counterpoint.place("3:1", :whole, "B4")
    end

    context "when the count is one" do
      let(:count) { 1 }
      let(:rhythmic_value) { :whole }

      it "uses the singular noun" do
        expect(guideline.message).to eq "Use one whole note in each middle bar."
      end
    end

    context "when the count is more than one" do
      let(:count) { 2 }
      let(:rhythmic_value) { :half }

      it "uses the plural noun" do
        expect(guideline.message).to eq "Use two half notes in each middle bar."
      end
    end
  end
end
