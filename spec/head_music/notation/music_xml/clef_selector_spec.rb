require "spec_helper"

describe HeadMusic::Notation::MusicXML::ClefSelector do
  subject(:clef) { described_class.for(voice) }

  let(:composition) { HeadMusic::Content::Composition.new }
  let(:voice) { composition.add_voice(role: "Melody") }

  context "when the voice sits high" do
    before do
      voice.place("1:1", :quarter, "C5")
      voice.place("1:2", :quarter, "E5")
    end

    it { is_expected.to eq HeadMusic::Rudiment::Clef.get(:treble_clef) }
  end

  context "when the voice sits low" do
    before do
      voice.place("1:1", :quarter, "C2")
      voice.place("1:2", :quarter, "C3")
    end

    it { is_expected.to eq HeadMusic::Rudiment::Clef.get(:bass_clef) }
  end

  context "when the voice straddles middle C with a midpoint exactly on it" do
    before do
      voice.place("1:1", :quarter, "C2")
      voice.place("1:2", :quarter, "C6")
    end

    it "resolves the midpoint to middle C" do
      midpoint = (voice.lowest_pitch.midi_note_number + voice.highest_pitch.midi_note_number) / 2.0
      expect(midpoint).to eq 60
    end

    it { is_expected.to eq HeadMusic::Rudiment::Clef.get(:treble_clef) }
  end

  context "when the voice straddles middle C with a midpoint just below it" do
    before do
      voice.place("1:1", :quarter, "B3")
      voice.place("1:2", :quarter, "C4")
    end

    it "resolves the midpoint below middle C" do
      midpoint = (voice.lowest_pitch.midi_note_number + voice.highest_pitch.midi_note_number) / 2.0
      expect(midpoint).to eq 59.5
    end

    it { is_expected.to eq HeadMusic::Rudiment::Clef.get(:bass_clef) }
  end

  context "when the voice has only rests" do
    before { voice.place("1:1", :whole) }

    it { is_expected.to eq HeadMusic::Rudiment::Clef.get(:treble_clef) }
  end

  context "when the voice has no placements" do
    it { is_expected.to eq HeadMusic::Rudiment::Clef.get(:treble_clef) }
  end

  describe "clef data used by the MusicXML writer" do
    it "gives treble clef a G sign on line 2" do
      voice.place("1:1", :quarter, "C5")
      expect(clef.pitch.letter_name.to_s).to eq "G"
      expect(clef.line).to eq 2
    end

    it "gives bass clef an F sign on line 4" do
      voice.place("1:1", :quarter, "C2")
      expect(clef.pitch.letter_name.to_s).to eq "F"
      expect(clef.line).to eq 4
    end
  end
end
