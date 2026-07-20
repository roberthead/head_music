require "spec_helper"

describe HeadMusic::Analysis::Dyad::ChordImplication do
  def pitch_class(name)
    HeadMusic::Rudiment::Pitch.get(name).pitch_class
  end

  subject(:implication) { described_class.new([pitch_class("C4"), pitch_class("E4")], key) }

  context "without a key" do
    let(:key) { nil }

    it "returns trichords that all contain the dyad" do
      dyad_classes = [pitch_class("C4"), pitch_class("E4")]
      expect(implication.trichords).to all(
        satisfy { |chord| dyad_classes.all? { |pc| chord.pitch_classes.include?(pc) } }
      )
    end

    it "finds the C major triad among the trichords" do
      c_major = implication.trichords.find(&:major_triad?)
      expect(c_major.pitches.map { |p| p.spelling.to_s }).to include("C", "E", "G")
    end

    it "returns seventh chords containing the dyad" do
      expect(implication.seventh_chords).to all(be_a(HeadMusic::Analysis::PitchCollection))
      expect(implication.seventh_chords.any?(&:seventh_chord?)).to be true
    end

    it "memoizes the trichords" do
      first_call = implication.trichords
      second_call = implication.trichords
      expect(first_call).to be second_call
    end

    it "memoizes the seventh chords" do
      first_call = implication.seventh_chords
      second_call = implication.seventh_chords
      expect(first_call).to be second_call
    end
  end

  context "with a key" do
    let(:key) { HeadMusic::Rudiment::Key.get("C major") }

    it "keeps only diatonic trichords" do
      diatonic = HeadMusic::Rudiment::Key.get("C major").scale.spellings
      expect(implication.trichords).to all(
        satisfy { |chord| chord.pitches.all? { |pitch| diatonic.include?(pitch.spelling) } }
      )
    end

    it "yields no more trichords than the unkeyed enumeration" do
      unkeyed = described_class.new([pitch_class("C4"), pitch_class("E4")], nil)
      expect(implication.trichords.length).to be <= unkeyed.trichords.length
    end
  end
end
