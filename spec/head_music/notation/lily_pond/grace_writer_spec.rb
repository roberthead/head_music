require "spec_helper"

describe HeadMusic::Notation::LilyPond::GraceWriter do
  let(:note) { HeadMusic::Content::Flow.new.add_voice.place("1:1", :whole, "C4") }

  describe ".token" do
    it "writes nothing for a note without grace notes" do
      expect(described_class.token(note)).to eq ""
    end

    it "writes one grace note without braces" do
      note.add_grace_note("D4", :sixteenth)
      expect(described_class.token(note)).to eq "\\grace d'16 "
    end

    it "braces several, ties the last into its main note, and opens a slur on the first" do
      note.add_grace_note("D4", :sixteenth).add_grace_note("C4", :sixteenth, tied: true)
      expect(described_class.token(note, slur_opens: "(")).to eq "\\grace { d'16( c'16~ } "
    end

    it "writes a slashed grace note with \\slashedGrace" do
      note.add_grace_note("D4", :eighth, slashed: true)
      expect(described_class.token(note)).to eq "\\slashedGrace d'8 "
    end

    it "writes \\acciaccatura where a slur from a slashed grace note to the main note is implied" do
      note.add_grace_note("D4", :eighth, slashed: true)
      expect(described_class.token(note, implied_slur: true)).to eq "\\acciaccatura d'8 "
    end

    it "writes \\appoggiatura where a slur from an unslashed grace note to the main note is implied" do
      note.add_grace_note("D4", :eighth)
      expect(described_class.token(note, implied_slur: true)).to eq "\\appoggiatura d'8 "
    end

    it "writes a command for each run of grace notes alike in slash" do
      note.add_grace_note("D4", :sixteenth, slashed: true).add_grace_note("E4", :sixteenth).add_grace_note("F4", :sixteenth)
      expect(described_class.token(note)).to eq "\\slashedGrace d'16 \\grace { e'16 f'16 } "
    end

    it "forces the accidentals of a grace chord's members at one letter and octave" do
      note.add_grace_note(%w[F4 F#4], :sixteenth)
      expect(described_class.token(note)).to eq "\\grace <fis'! f'!>16 "
    end

    it "writes a grace chord low to high, with its articulations" do
      note.add_grace_note(%w[C5 A4], :sixteenth, articulations: [:staccato])
      expect(described_class.token(note)).to eq "\\grace <a' c''>16-. "
    end
  end
end
