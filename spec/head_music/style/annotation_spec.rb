# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Style::Annotation do
  let(:voice) { HeadMusic::Content::Voice.new }

  context "when the voice is compliant" do
    subject(:annotation) { HeadMusic::Style::Guidelines::UpToFourteenNotes.new(voice) }

    it { is_expected.to be_adherent }
  end

  context "when the voice is not compliant" do
    subject(:annotation) { HeadMusic::Style::Guidelines::AtLeastEightNotes.new(voice) }

    it { is_expected.not_to be_adherent }
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
