require "spec_helper"

describe HeadMusic::Style::Guidelines::EndOnTonic do
  subject { assess(described_class, voice) }

  let(:voice) { HeadMusic::Content::Voice.new }

  context "with no notes" do
    subject(:guideline) { assess(described_class, voice) }

    it { is_expected.to be_adherent }

    it "returns nil for the last note spelling" do
      analyzer = described_class.send(:new, voice)
      expect(analyzer.send(:last_note_spelling)).to be_nil
    end
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
    context "when tonic_spelling is nil" do
      subject(:guideline) { assess(described_class, voice) }

      let(:mock_key_signature) { instance_double(HeadMusic::Rudiment::KeySignature, tonic_spelling: nil) }

      before do
        voice.place("1:1", :whole, "C")
        flow = voice.flow
        allow(flow).to receive(:key_signature).and_return(mock_key_signature)
      end

      it "handles nil tonic_spelling gracefully" do
        expect(guideline.fitness).to be < 1 # should create a mark when tonic is nil
      end
    end
  end
end
