require "spec_helper"

describe HeadMusic::Style::Guideline do
  let(:voice) { HeadMusic::Content::Voice.new }

  context "when the voice is empty" do
    describe "with a maximum-notes guideline" do
      subject(:analyzer) { HeadMusic::Style::Guidelines::MaximumNotes.send(:new, voice, maximum: 14) }

      its(:first_note) { is_expected.to be_nil }
      its(:last_note) { is_expected.to be_nil }
      it { is_expected.not_to have_notes }
      it { is_expected.to be_adherent }
    end

    context "with a minimum-notes guideline" do
      subject(:analyzer) { HeadMusic::Style::Guidelines::MinimumNotes.send(:new, voice, minimum: 8) }

      it { is_expected.not_to be_adherent }
    end
  end

  context "when there are multiple marks" do
    subject(:analyzer) { HeadMusic::Style::Guidelines::Diatonic.send(:new, voice) }

    before do
      voice.place("1:1:0", :whole, "C4")
      voice.place("2:1:0", :whole, "C#4")
      voice.place("3:1:0", :whole, "D4")
      voice.place("4:1:0", :whole, "D#4")
      voice.place("5:1:0", :whole, "E4")
    end

    specify { expect(analyzer.marks.length).to eq 2 }
    specify { expect(analyzer.marks[0].start_position).to eq "2:1:0" }
    specify { expect(analyzer.marks[1].start_position).to eq "4:1:0" }
    specify { expect(analyzer.start_position).to eq "2:1:0" }
    specify { expect(analyzer.end_position).to eq "5:1:0" }
  end
end
