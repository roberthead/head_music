require "spec_helper"

describe HeadMusic::Notation::LilyPond::Graces do
  describe described_class::Grace do
    subject(:grace) do
      described_class.new(
        pitches: [d4], rhythmic_value: HeadMusic::Rudiment::RhythmicValue.get(:sixteenth), slashed: true, tied: true,
        marks: HeadMusic::Notation::LilyPond::MarkReader::Marks.new(articulations: ["staccato"])
      )
    end

    let(:c4) { HeadMusic::Rudiment::Pitch.get("C4") }
    let(:d4) { HeadMusic::Rudiment::Pitch.get("D4") }

    it "keeps its tie only into the same pitches" do
      expect([grace.before([d4]).tied, grace.before([c4]).tied]).to eq [true, false]
    end

    it "makes the grace note the model holds" do
      expect(grace.grace_note.to_h).to include("slashed" => true, "tied" => true, "articulations" => ["staccato"])
    end
  end

  describe "NONE" do
    let(:marks) { HeadMusic::Notation::LilyPond::MarkReader::Marks.new(articulations: ["accent"], level: "p") }

    it "leaves the main note's marks as they are" do
      expect(described_class::NONE.main_marks(marks)).to eq marks
    end

    it "puts no grace notes before the main note" do
      expect(described_class::NONE.before([HeadMusic::Rudiment::Pitch.get("C4")])).to eq []
    end
  end
end
