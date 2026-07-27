require "spec_helper"

describe HeadMusic::Utilities::HashKey do
  describe ".for" do
    it "strips diacritics" do
      expect(described_class.for("Violinschlüssel")).to eq :violinschlussel
    end

    it "underscores" do
      expect(described_class.for("French Horn")).to eq :french_horn
    end
  end

  # Accidental signs become word suffixes. Doubles are matched before singles: the
  # single-sharp rule would otherwise consume the first character of "##" and leave a
  # stray "#" behind.
  describe "accidental signs" do
    {
      "C♯" => :c_sharp,
      "C#" => :c_sharp,
      "C♭" => :c_flat,
      "C𝄪" => :c_double_sharp,
      "C##" => :c_double_sharp,
      "C𝄫" => :c_double_flat,
      "C♮" => :c_natural,
      "C sharp" => :c_sharp,
      "D flat" => :d_flat,

      # ASCII spellings normalize through Accidentals before the glyphs are mapped.
      # Handling ASCII "#" but not ASCII "b" previously left the two sides asymmetric,
      # with "C#" keying to :c_sharp while "Bb" keyed to :bb.
      "Bb" => :b_flat,
      "Bbb" => :b_double_flat,
      "Cx" => :c_double_sharp,
      "Eb3" => :e_flat3,

      # Normalizing ASCII flats is only safe because Accidentals.to_unicode will not
      # touch a lowercase word. A bare substitution turns these into
      # :b_flatass_clarinet and :b_fluesmajor_pentatonic.
      "blues_major_pentatonic" => :blues_major_pentatonic,
      "bass clarinet" => :bass_clarinet,
      "double bass" => :double_bass,
      "Abbreviation" => :abbreviation,
      "Bebop" => :bebop,
      "English horn" => :english_horn,
      "Violinschlüssel" => :violinschlussel
    }.each do |identifier, expected|
      it "keys #{identifier} as #{expected}" do
        expect(described_class.for(identifier)).to eq expected
      end
    end

    [%w[Bb B♭], %w[Bbb B𝄫], %w[Cx C𝄪], %w[C# C♯], %w[C## C𝄪], %w[Eb3 E♭3]].each do |ascii, unicode|
      it "keys #{ascii} and #{unicode} identically" do
        expect(described_class.for(ascii)).to eq described_class.for(unicode)
      end
    end
  end
end
