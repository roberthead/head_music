require "spec_helper"

describe HeadMusic::Notation::LilyPond::TimedMarks do
  let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nT:Marks\nL:1/4\nM:4/4\nK:C\nC3 D|E4|\n") }
  let(:voice) { flow.voices.first }

  def marks(*positions_and_tokens)
    described_class.new(positions_and_tokens.map { |position, token| described_class.mark(flow.position(position), token, "mark") })
  end

  describe ".duration" do
    {Rational(1, 4) => "4", Rational(3, 8) => "4.", Rational(7, 16) => "4..", Rational(5, 8) => "1*5/8", Rational(1, 3840) => "1*1/3840"}
      .each do |fraction, written|
        it "writes #{fraction} of a whole note as #{written}" do
          expect(described_class.duration(fraction)).to eq written
        end
      end
  end

  describe "#attacks" do
    it "answers the marks where a link starts, in order of position" do
      expect(marks(["1:4", "\\f"], ["1:1", "\\p"]).attacks(1, Rational(3, 4))).to eq "\\f"
    end

    it "answers nothing in another bar" do
      expect(marks(["1:1", "\\p"]).attacks(2, 0r)).to eq ""
    end
  end

  describe "#afters" do
    it "wraps the link in an \\after for each mark inside it, measured from the link's start" do
      expect(marks(["1:2", "\\p"], ["1:4", "\\f"]).afters(1, 0r, 1r)).to eq "\\after 4 \\p \\after 2. \\f "
    end

    it "leaves out a mark where the link starts or ends" do
      expect(marks(["1:1", "\\p"], ["1:4", "\\f"]).afters(1, 0r, Rational(3, 4))).to eq ""
    end
  end

  describe "#trailing" do
    it "answers the marks at or after the end of the music in the bar" do
      expect(marks(["1:2", "\\p"], ["1:4", "\\f"]).trailing(1, Rational(3, 4)).map(&:token)).to eq ["\\f"]
    end
  end

  describe ".levels" do
    it "takes the voice's levels" do
      voice.place_dynamic("1:2", :p)
      expect(described_class.levels(voice).afters(1, 0r, Rational(3, 4))).to eq "\\after 4 \\p "
    end

    it "leaves out a level an accent on its note overrides" do
      voice.voice_events.first.note_dynamic = :fp
      voice.place_dynamic("1:1", :f)
      expect(described_class.levels(voice).attacks(1, 0r)).to eq ""
    end
  end
end
