require "spec_helper"

describe HeadMusic::Style::Annotation do
  let(:voice) { HeadMusic::Content::Voice.new }

  context "when the voice is empty" do
    describe "with a maximum-notes guideline" do
      subject(:annotation) { HeadMusic::Style::Guidelines::MaximumNotes.new(voice, maximum: 14) }

      its(:first_note) { is_expected.to be_nil }
      its(:last_note) { is_expected.to be_nil }
      it { is_expected.not_to have_notes }
      it { is_expected.to be_adherent }
    end

    context "with a minimum-notes guideline" do
      subject(:annotation) { HeadMusic::Style::Guidelines::MinimumNotes.new(voice, minimum: 8) }

      it { is_expected.not_to be_adherent }
    end
  end

  describe "#weight" do
    it "defaults to 1.0" do
      annotation = HeadMusic::Style::Guidelines::MaximumNotes.new(voice, maximum: 14)
      expect(annotation.weight).to eq 1.0
    end

    it "uses a subclass's default_weight override" do
      annotation = HeadMusic::Style::Guidelines::Contoured.new(voice, contour: :arch)
      expect(annotation.weight).to eq HeadMusic::GOLDEN_RATIO_INVERSE
    end

    it "can be overridden with a weight option" do
      annotation = HeadMusic::Style::Guidelines::MaximumNotes.with(14).with(weight: 2.0).new(voice)
      expect(annotation.weight).to eq 2.0
    end
  end

  describe "#gate?" do
    it "defaults to false" do
      annotation = HeadMusic::Style::Guidelines::MaximumNotes.new(voice, maximum: 14)
      expect(annotation.gate?).to be false
    end

    it "can be overridden with a gate option" do
      annotation = HeadMusic::Style::Guidelines::MaximumNotes.with(14).with(gate: true).new(voice)
      expect(annotation.gate?).to be true
    end

    it "uses a subclass's default_gate? override" do
      annotation = HeadMusic::Style::Guidelines::MinimumNotes.new(voice, minimum: 8)
      expect(annotation.gate?).to be true
    end
  end

  describe "Configured#with" do
    it "merges additional options without dropping prior options" do
      configured = HeadMusic::Style::Guidelines::MinimumNotes.with(8).with(weight: 0.5)
      expect(configured.options).to eq(minimum: 8, weight: 0.5)
    end
  end

  context "when there are multiple marks" do
    subject(:annotation) { HeadMusic::Style::Guidelines::Diatonic.new(voice) }

    before do
      voice.place("1:1:0", :whole, "C4")
      voice.place("2:1:0", :whole, "C#4")
      voice.place("3:1:0", :whole, "D4")
      voice.place("4:1:0", :whole, "D#4")
      voice.place("5:1:0", :whole, "E4")
    end

    specify { expect(annotation.marks.length).to eq 2 }
    specify { expect(annotation.marks[0].start_position).to eq "2:1:0" }
    specify { expect(annotation.marks[1].start_position).to eq "4:1:0" }
    specify { expect(annotation.start_position).to eq "2:1:0" }
    specify { expect(annotation.end_position).to eq "5:1:0" }
  end
end
