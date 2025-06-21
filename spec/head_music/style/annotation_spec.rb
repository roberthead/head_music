require "spec_helper"

describe HeadMusic::Style::Annotation do
  let(:voice) { HeadMusic::Content::Voice.new }

  context "when the voice is empty" do
    describe "with up-to-fourteen-notes" do
      subject(:annotation) { HeadMusic::Style::Guidelines::UpToFourteenNotes.new(voice) }

      its(:first_note) { is_expected.to be_nil }
      its(:last_note) { is_expected.to be_nil }
      it { is_expected.not_to have_notes }
      it { is_expected.to be_adherent }
    end

    context "with at-least-eight-notes" do
      subject(:annotation) { HeadMusic::Style::Guidelines::AtLeastEightNotes.new(voice) }

      it { is_expected.not_to be_adherent }
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
