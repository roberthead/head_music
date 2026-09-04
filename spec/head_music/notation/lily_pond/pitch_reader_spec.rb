require "spec_helper"

describe HeadMusic::Notation::LilyPond::PitchReader do
  def tokens(source)
    HeadMusic::Notation::LilyPond::Lexer.new(source).tokens
  end

  def token(source)
    tokens(source).first
  end

  describe ".absolute" do
    subject(:reader) { described_class.absolute }

    it "is not relative" do
      expect(reader).not_to be_relative
    end

    {
      "c" => "C3", "c'" => "C4", "c''" => "C5", "c," => "C2", "c,," => "C1",
      "b'" => "B4", "a" => "A3",
      "cis'" => "C♯4", "ees'" => "E♭4", "es'" => "E♭4", "as" => "A♭3", "fisis'" => "F𝄪4", "beses" => "B𝄫3", "ases" => "A𝄫3"
    }.each do |source, expected|
      it "reads #{source} as #{expected}" do
        expect(reader.pitch(token(source)).to_s).to eq expected
      end
    end

    it "reads every alteration the writer emits back to its semitones" do
      HeadMusic::Notation::LilyPond::PitchWriter::ALTERATION_SUFFIXES.each do |semitones, suffix|
        expect(reader.pitch(token("c#{suffix}'")).alteration_semitones.to_i).to eq semitones
      end
    end

    it "does not change a previous note's octave" do
      reader.pitch(token("c'''"))
      expect(reader.pitch(token("c")).to_s).to eq "C3"
    end

    it "raises for a pitch above the supported range" do
      expect { reader.pitch(token("c'''''''")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Pitch "c'''''''" is out of range/)
    end

    it "raises for a pitch below the supported range" do
      expect { reader.pitch(token("c,,,,,")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /out of range/)
    end

    it "raises for octave marks far beyond the supported range" do
      expect { reader.pitch(token("c,,,,,,,,,,")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /out of range/)
    end

    it "raises rather than falling back to the default register" do
      expect { reader.pitch(token("c''''''''''")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /out of range/)
    end

    it "reads chord pitches independently" do
      expect(reader.chord_pitches(tokens("c' e' g'")).map(&:to_s)).to eq %w[C4 E4 G4]
    end
  end

  describe ".relative" do
    def read(reference, source)
      reader = described_class.relative(reference)
      tokens(source).map { |token| reader.pitch(token).to_s }
    end

    it "is relative" do
      expect(described_class.relative("C4")).to be_relative
    end

    # Each row was checked against the lilypond binary.
    {
      ["C4", "g"] => %w[G3],
      ["C4", "g'"] => %w[G4],
      ["C4", "f"] => %w[F4],
      ["C4", "b"] => %w[B3],
      ["C4", "c,"] => %w[C3],
      ["B2", "c"] => %w[C3],
      ["C4", "fis"] => %w[F♯4],
      ["Bb4", "e"] => %w[E5],
      ["C4", "e''"] => %w[E6],
      ["C4", "c"] => %w[C4],
      ["C4", "d"] => %w[D4],
      ["C4", "a"] => %w[A3],
      ["F3", "c d"] => %w[C3 D3],
      ["C4", "g a b c d c b g"] => %w[G3 A3 B3 C4 D4 C4 B3 G3]
    }.each do |(reference, source), expected|
      it "reads #{source} after #{reference} as #{expected.join(" ")}" do
        expect(read(reference, source)).to eq expected
      end
    end

    it "ignores accidentals when choosing the octave" do
      expect(read("C4", "fis ges")).to eq %w[F♯4 G♭4]
    end

    it "measures from the previous note, not the reference" do
      expect(read("C4", "g e")).to eq %w[G3 E3]
    end

    it "treats a fourth down as closer than a fifth up" do
      expect(read("C4", "g d")).to eq %w[G3 D3]
    end

    it "raises for a pitch driven out of range" do
      expect { read("C4", "c'''''''") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /out of range/)
    end

    describe "#chord_pitches" do
      it "resolves each chord note relative to the one before it" do
        reader = described_class.relative("C4")
        expect(reader.chord_pitches(tokens("c e g")).map(&:to_s)).to eq %w[C4 E4 G4]
      end

      it "leaves the chord's first note as the reference" do
        reader = described_class.relative("C4")
        reader.chord_pitches(tokens("e g b"))
        expect(reader.pitch(token("d")).to_s).to eq "D4"
      end
    end
  end
end
