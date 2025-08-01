require "spec_helper"

describe HeadMusic::Style::Guidelines::EndOnTonic do
  subject { described_class.new(voice) }

  let(:voice) { HeadMusic::Content::Voice.new }

  context "with no notes" do
    it { is_expected.to be_adherent }
  end

  context "when the last note is the tonic" do
    before do
      voice.place("1:1", :whole, "C")
      voice.place("2:1", :whole, "D")
      voice.place("3:1", :whole, "C")
    end

    it { is_expected.to be_adherent }
  end

  context "when the first note is NOT the tonic" do
    before do
      voice.place("1:1", :whole, "D")
      voice.place("2:1", :whole, "E")
      voice.place("3:1", :whole, "D")
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:marks_count) { is_expected.to eq 1 }
    its(:message) { is_expected.not_to be_empty }
    its(:first_mark_code) { is_expected.to eq "3:1:000 to 4:1:000" }
  end

  context "with edge cases for branch coverage" do
    context "when last_note_spelling is nil but notes exist" do
      subject(:guideline) { described_class.new(voice) }

      before do
        # Create a note with nil pitch to test the nil branch in ends_on_tonic?
        note_with_nil_pitch = HeadMusic::Content::Note.new(nil, :whole, voice, "1:1:000")
        allow(voice).to receive(:notes).and_return([note_with_nil_pitch])
      end

      it "handles nil last_note_spelling gracefully" do
        expect(guideline).not_to be_adherent # should create a mark when spelling is nil
      end
    end

    context "when tonic_spelling is nil" do
      subject(:guideline) { described_class.new(voice) }

      let(:mock_key_signature) { instance_double(HeadMusic::Rudiment::KeySignature, tonic_spelling: nil) }

      before do
        voice.place("1:1", :whole, "C")
        composition = voice.composition
        allow(composition).to receive(:key_signature).and_return(mock_key_signature)
      end

      it "handles nil tonic_spelling gracefully" do
        expect(guideline.fitness).to be < 1 # should create a mark when tonic is nil
      end
    end
  end
end
