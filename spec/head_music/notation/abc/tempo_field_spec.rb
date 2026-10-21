require "spec_helper"

describe HeadMusic::Notation::ABC::TempoField do
  def tempo(beat, beats_per_minute, **options)
    HeadMusic::Rudiment::Tempo.new(beat, beats_per_minute, **options)
  end

  describe ".read" do
    def read(value, unit_note_length = Rational(1, 8))
      described_class.read(value, unit_note_length)
    end

    {
      "1/4=120" => ["quarter", 120],
      "3/8=60" => ["dotted quarter", 60],
      "1/2 = 66" => ["half", 66],
      "1/4=92.5" => ["quarter", 92.5],
      "1/8 1/8=40" => ["quarter", 40],
      "120" => ["eighth", 120],
      "C=96" => ["eighth", 96],
      "C3=40" => ["dotted quarter", 40]
    }.each do |value, (beat, beats_per_minute)|
      it "reads #{value.inspect} as a #{beat} at #{beats_per_minute}" do
        expect(read(value)).to eq tempo(beat, beats_per_minute)
      end
    end

    it "reads the text before the number" do
      expect(read('"Allegro" 1/4=120')).to eq tempo("quarter", 120, text: "Allegro")
    end

    it "reads the text after the number" do
      expect(read('1/4=120 "Allegro"')).to eq tempo("quarter", 120, text: "Allegro")
    end

    it "reads text alone as tempo text with no metronome mark" do
      expect(read('"Andante"')).to eq HeadMusic::Rudiment::Tempo.for_text("Andante")
    end

    it "keeps only the text where no single note value spans the beat" do
      expect(read('"Lento" 1/4 1/16=40')).to eq HeadMusic::Rudiment::Tempo.for_text("Lento")
    end

    it "answers nil for a field with nothing it can hold" do
      expect([read("1/4 1/16=40"), read(""), read('""')]).to all(be_nil)
    end

    ["fast", "1/4=", "1/4=0"].each do |value|
      it "raises for #{value.inspect}" do
        expect { described_class.read(value, Rational(1, 8), line_number: 7) }
          .to raise_error(HeadMusic::Notation::ABC::ParseError, /Invalid tempo.*line 7/)
      end
    end
  end

  describe ".write" do
    it "writes a beat and its count" do
      expect(described_class.write(tempo("dotted quarter", 60))).to eq "3/8=60"
    end

    it "writes the text before the number" do
      expect(described_class.write(tempo("quarter", 120, text: "Allegro"))).to eq '"Allegro" 1/4=120'
    end

    it "writes only the text where the number was not written" do
      expect(described_class.write(HeadMusic::Rudiment::Tempo.get("allegro"))).to eq '"allegro"'
    end
  end

  describe ".problem" do
    it "names a fractional tempo" do
      expect(described_class.problem(tempo("quarter", 92.5))).to eq "the fractional tempo of 92.5 beats per minute"
    end

    it "names text holding a double quote" do
      expect(described_class.problem(tempo("quarter", 92, text: 'So "fast"'))).to include("double quote")
    end

    it "answers nil for a tempo it can write" do
      expect(described_class.problem(tempo("quarter", 92, text: "Allegro"))).to be_nil
    end
  end
end
