require "spec_helper"

describe HeadMusic::Analysis::PitchSpeller do
  def spell(numbers, key:, voice: :melody)
    notes = numbers.each_with_index.map { |number, index| [number, Rational(index, 4), Rational(1, 4), voice] }
    described_class.new(notes, key: key)
  end

  def names(numbers, key:)
    spell(numbers, key: key).pitches.map(&:to_s)
  end

  def rules(numbers, key:)
    spell(numbers, key: key).spelled_notes.map(&:rule)
  end

  describe "the key's collection" do
    it "spells E♭ major's 63 and 68 as E♭ and A♭" do
      expect(names([63, 68], key: "E♭ major")).to eq %w[E♭4 A♭4]
    end

    it "spells a note in the collection diatonically" do
      expect(rules([63, 68], key: "E♭ major")).to eq %i[diatonic diatonic]
    end

    it "spells G♭ major's 59 as C♭4, in the register above" do
      expect(names([59], key: "G♭ major")).to eq %w[C♭4]
    end
  end

  describe "a minor key's raised 6th and 7th" do
    it "spells A minor's 68 as G♯" do
      expect(names([68], key: "A minor")).to eq %w[G♯4]
    end

    it "spells G♯ minor's 67 as F𝄪" do
      expect(names([67], key: "G♯ minor")).to eq %w[F𝄪4]
    end

    it "spells A minor's 66 as F♯" do
      expect(names([66], key: "A minor")).to eq %w[F♯4]
    end

    it "answers the raised rule" do
      expect(rules([66, 68], key: "A minor")).to eq %i[raised raised]
    end
  end

  describe "with a mode" do
    it "spells G Dorian's 66 as F♯" do
      expect(names([66], key: HeadMusic::Rudiment::Mode.get("G dorian"))).to eq %w[F♯4]
    end

    it "uses the mode's own collection" do
      expect(names([70, 64], key: "G dorian")).to eq %w[B♭4 E4]
    end

    it "spells a major-like mode's chromatic notes from its center" do
      expect(names([65, 66], key: "G mixolydian")).to eq %w[F4 F♯4]
    end
  end

  describe "with a key signature" do
    let(:key) { HeadMusic::Rudiment::KeySignature.get("B♭ major") }

    it "spells its collection diatonically and the rest from its center" do
      expect(spell([70, 66], key: key).spelled_notes.map { |spelled| [spelled.pitch.to_s, spelled.rule] })
        .to eq [["B♭4", :diatonic], ["F♯4", :center]]
    end
  end

  describe "a chromatic note far from a near tie" do
    it "spells C major's 66 as F♯ and 70 as B♭ from the center" do
      expect(spell([66, 70], key: "C major").spelled_notes.map { |spelled| [spelled.pitch.to_s, spelled.rule] })
        .to eq [["F♯4", :center], ["B♭4", :center]]
    end
  end

  describe "every key from six flats to six sharps" do
    keys = (-6..6).flat_map do |fifths|
      major = HeadMusic::Rudiment::Key.for_fifths(fifths)
      [major, major.relative]
    end

    keys.each do |key|
      it "spells each pitch class alone with at most one accidental in #{key}" do
        raised_seventh = (key.tonic_pitch.pitch_class.to_i - 1) % 12 if key.minor?
        accidentals = (60..71).reject { |number| number % 12 == raised_seventh }.map do |number|
          described_class.new([[number, 0, 1]], key: key).pitches.first.spelling.alteration&.semitones.to_i.abs
        end
        expect(accidentals.max).to be <= 1
      end
    end
  end

  describe "the key given" do
    let(:regions) do
      [
        HeadMusic::Analysis::KeyRegion.new(bar_number: 2, onset: 1, key: HeadMusic::Rudiment::Key.get("A♭ major")),
        HeadMusic::Analysis::KeyRegion.new(bar_number: 1, onset: 0, key: HeadMusic::Rudiment::Key.get("E major"))
      ]
    end

    it "takes a Key" do
      expect(names([68], key: HeadMusic::Rudiment::Key.get("A♭ major"))).to eq %w[A♭4]
    end

    it "takes key regions, switching key at each region's onset" do
      notes = [[68, 0, 1], [68, 1, 1]]
      expect(described_class.new(notes, key: regions, meter: "4/4").pitches.map(&:to_s)).to eq %w[G♯4 A♭4]
    end

    it "refuses anything else" do
      expect { described_class.new([[60, 0, 1]], key: 3) }.to raise_error(ArgumentError)
    end
  end

  describe "#spelled_notes" do
    subject(:spelled_notes) { spell([62, 60], key: "C major").spelled_notes }

    it "answers each note with its pitch, in input order" do
      expect(spelled_notes.map { |spelled| [spelled.note.number, spelled.pitch.to_s] }).to eq [[62, "D4"], [60, "C4"]]
    end

    it "answers the same spelling for the same input" do
      expect(spelled_notes).to eq spell([62, 60], key: "C major").spelled_notes
    end
  end

  describe "a spelling the pitch catalog cannot hold" do
    it "falls back to the sharp spelling" do
      expect(spell([0], key: "C♯ major").spelled_notes.map { |spelled| [spelled.pitch.to_s, spelled.rule] })
        .to eq [["C-1", :fallback]]
    end
  end
end
