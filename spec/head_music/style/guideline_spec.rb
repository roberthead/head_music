require "spec_helper"

describe HeadMusic::Style::Guideline do
  let(:voice) { HeadMusic::Content::Voice.new }

  context "when the voice is empty" do
    describe "with a maximum-notes guideline" do
      subject(:guideline) { HeadMusic::Style::Guidelines::MaximumNotes.new(voice, maximum: 14) }

      its(:first_note) { is_expected.to be_nil }
      its(:last_note) { is_expected.to be_nil }
      it { is_expected.not_to have_notes }
      it { is_expected.to be_adherent }
    end

    context "with a minimum-notes guideline" do
      subject(:guideline) { HeadMusic::Style::Guidelines::MinimumNotes.new(voice, minimum: 8) }

      it { is_expected.not_to be_adherent }
    end
  end

  describe "#weight" do
    it "defaults to 1.0" do
      guideline = HeadMusic::Style::Guidelines::MaximumNotes.new(voice, maximum: 14)
      expect(guideline.weight).to eq 1.0
    end

    it "uses a subclass's default_weight override" do
      guideline = HeadMusic::Style::Guidelines::Contoured.new(voice, contour: :arch)
      expect(guideline.weight).to eq HeadMusic::GOLDEN_RATIO_INVERSE
    end

    it "can be overridden with a weight option" do
      guideline = HeadMusic::Style::Guidelines::MaximumNotes.with(14).with(weight: 2.0).new(voice)
      expect(guideline.weight).to eq 2.0
    end
  end

  describe "#gate?" do
    it "defaults to false" do
      guideline = HeadMusic::Style::Guidelines::MaximumNotes.new(voice, maximum: 14)
      expect(guideline.gate?).to be false
    end

    it "can be overridden with a gate option" do
      guideline = HeadMusic::Style::Guidelines::MaximumNotes.with(14).with(gate: true).new(voice)
      expect(guideline.gate?).to be true
    end

    it "uses a subclass's default_gate? override" do
      guideline = HeadMusic::Style::Guidelines::MinimumNotes.new(voice, minimum: 8)
      expect(guideline.gate?).to be true
    end
  end

  describe "Configured#with" do
    it "merges additional options without dropping prior options" do
      configured = HeadMusic::Style::Guidelines::MinimumNotes.with(8).with(weight: 0.5)
      expect(configured.config).to eq(minimum: 8, weight: 0.5)
    end
  end

  context "when there are multiple marks" do
    subject(:guideline) { HeadMusic::Style::Guidelines::Diatonic.new(voice) }

    before do
      voice.place("1:1:0", :whole, "C4")
      voice.place("2:1:0", :whole, "C#4")
      voice.place("3:1:0", :whole, "D4")
      voice.place("4:1:0", :whole, "D#4")
      voice.place("5:1:0", :whole, "E4")
    end

    specify { expect(guideline.marks.length).to eq 2 }
    specify { expect(guideline.marks[0].start_position).to eq "2:1:0" }
    specify { expect(guideline.marks[1].start_position).to eq "4:1:0" }
    specify { expect(guideline.start_position).to eq "2:1:0" }
    specify { expect(guideline.end_position).to eq "5:1:0" }
  end
end
