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

  describe "melodic direction" do
    it "raises C major's 61 rising a semitone to 62" do
      expect(spell([60, 61, 62], key: "C major").spelled_notes.map { |spelled| [spelled.pitch.to_s, spelled.rule] }[1]).to eq ["C♯4", :direction]
    end

    it "lowers C major's 61 falling a semitone to 60" do
      expect(names([62, 61, 60], key: "C major")).to eq %w[D4 D♭4 C4]
    end

    it "answers the direction rule" do
      expect(rules([62, 61, 60], key: "C major")).to eq %i[diatonic direction diatonic]
    end

    it "decides C major's 63 both ways" do
      expect([names([62, 63, 64], key: "C major"), names([64, 63, 62], key: "C major")]).to eq [%w[D4 D♯4 E4], %w[E4 E♭4 D4]]
    end

    it "keeps F♯ falling from G to F, since F♯ and G♭ are no near tie" do
      expect(names([67, 66, 65], key: "C major")).to eq %w[G4 F♯4 F4]
    end

    it "keeps B♭ rising from A to B" do
      expect(names([69, 70, 71], key: "C major")).to eq %w[A4 B♭4 B4]
    end

    it "ignores a semitone into another voice" do
      notes = [[61, 0, Rational(1, 4), :upper], [60, Rational(1, 4), Rational(1, 4), :lower]]
      expect(described_class.new(notes, key: "C major").pitches.map(&:to_s)).to eq %w[C♯4 C4]
    end

    it "does not apply to notes with no voice" do
      expect(names([62, 61, 60], key: "C major").zip(spell([62, 61, 60], key: "C major", voice: nil).pitches.map(&:to_s)))
        .to eq [%w[D4 D4], %w[D♭4 C♯4], %w[C4 C4]]
    end
  end

  describe "the sonority" do
    def chord(numbers, key:, also: [])
      notes = numbers.map { |number| [number, 0, 1] } + also
      described_class.new(notes, key: key).spelled_notes
    end

    it "spells F minor's 61–65–68 as D♭–F–A♭ from the key alone" do
      expect(chord([61, 65, 68], key: "F minor").map { |spelled| [spelled.pitch.to_s, spelled.rule] })
        .to eq [["D♭4", :diatonic], ["F4", :diatonic], ["A♭4", :diatonic]]
    end

    it "spells C major's 61–65–68 sounding alone as D♭–F–A♭" do
      expect(chord([61, 65, 68], key: "C major").map { |spelled| [spelled.pitch.to_s, spelled.rule] })
        .to eq [["D♭4", :sonority], ["F4", :diatonic], ["A♭4", :sonority]]
    end

    it "spells A–C♯–E–G in C major with C♯" do
      expect(chord([57, 61, 64, 67], key: "C major").map { |spelled| [spelled.pitch.to_s, spelled.rule] }[1]).to eq ["C♯4", :sonority]
    end

    it "holds a note already sounding fixed" do
      spelled = chord([], key: "C major", also: [[65, 0, 1], [61, Rational(1, 2), Rational(1, 2)], [68, Rational(1, 2), Rational(1, 2)]])
      expect(spelled.map { |note| note.pitch.to_s }).to eq %w[F4 D♭4 A♭4]
    end

    it "ignores a note that has stopped sounding" do
      spelled = chord([64], key: "C major", also: [[65, 0, Rational(1, 2)], [61, Rational(1, 2), Rational(1, 2)], [68, Rational(1, 2), Rational(1, 2)]])
      expect(spelled.map { |note| [note.pitch.to_s, note.rule] }.last(2)).to eq [["C♯4", :sonority], ["G♯4", :sonority]]
    end

    it "yields to melodic direction" do
      notes = [[65, 0, 1, :alto], [61, 0, Rational(1, 2), :soprano], [62, Rational(1, 2), Rational(1, 2), :soprano]]
      expect(described_class.new(notes, key: "C major").spelled_notes.map(&:rule)).to eq %i[diatonic direction diatonic]
    end

    it "settles up to 4,096 combinations" do
      numbers = [1, 13, 25, 37, 49, 61, 73, 85, 97, 109, 8, 20]
      expect(chord(numbers + [65], key: "C major").map(&:rule).tally).to eq(sonority: 12, diatonic: 1)
    end

    it "spells from the center past 4,096 combinations" do
      numbers = [1, 13, 25, 37, 49, 61, 73, 85, 97, 109, 8, 20, 32]
      expect(chord(numbers + [65], key: "C major").map { |spelled| [spelled.pitch.spelling.to_s, spelled.rule] }.uniq)
        .to eq [["C♯", :center], ["G♯", :center], ["F", :diatonic]]
    end
  end

  describe "the center" do
    it "takes the sharper of an exact tie" do
      expect(spell([68], key: "C major").spelled_notes.map { |spelled| [spelled.pitch.to_s, spelled.rule] }).to eq [["G♯4", :center]]
    end
  end

  it "answers every rule" do
    notes = [[60, 0, 1, :a], [61, 1, 1, :a], [62, 2, 1, :a], [65, 3, 1, :b], [68, 3, 1, :c], [66, 4, 1, :a]]
    rules = described_class.new(notes, key: "C major").spelled_notes.map(&:rule) +
      described_class.new([[68, 0, 1]], key: "A minor").spelled_notes.map(&:rule) +
      described_class.new([[0, 0, 1]], key: "C♯ major").spelled_notes.map(&:rule)
    expect(rules.uniq.sort).to eq %i[center diatonic direction fallback raised sonority]
  end
end
