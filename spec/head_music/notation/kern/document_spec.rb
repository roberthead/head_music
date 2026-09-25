require "spec_helper"

describe HeadMusic::Notation::Kern::Document do
  def document(source)
    described_class.new(HeadMusic::Notation::Kern::Lexer.new(source).records)
  end

  def lines(*rows)
    rows.join("\n")
  end

  describe "spines" do
    subject(:header) { document(lines("**kern\t**text\t**dynam\t**kern", "4c\tla\tp\t4e", "*-\t*-\t*-\t*-")) }

    it "keeps the header's tracks" do
      expect(header.header_tracks.map(&:kind)).to eq %i[kern lyric skipped kern]
    end

    it "selects the kern tracks" do
      expect(header.kern_tracks.map(&:origin)).to eq [0, 3]
    end

    it "pairs each row after the header with its tracks" do
      expect(header.rows.map { |row| row.tracks.length }).to eq [4, 4]
    end
  end

  describe "spine manipulation" do
    subject(:split) do
      document(lines("**kern", "*^", "4c\t4e", "*v\t*v", "4d", "*-"))
    end

    it "checks each row against the tracks live when it is read" do
      expect(split.rows.map { |row| row.tracks.length }).to eq [1, 2, 2, 1, 1]
    end

    it "records what a manipulator row changed" do
      expect(split.rows.map { |row| row.manipulations.map(&:type) }).to eq [[:split], [], [:join], [], [:end]]
    end

    it "accepts a spine ended before the others" do
      expect { document(lines("**kern\t**kern", "4c\t4e", "*-\t*", "4d", "*-")) }.not_to raise_error
    end
  end

  describe "citation records" do
    subject(:cited) do
      document(lines(
        "!!!!SEGMENT: chorale.krn",
        "!!!COM: Bach, Johann Sebastian",
        "!!!COM: Anonymous",
        "!!!CDT: 1685/02/21/-1750/07/28/",
        "!!!OTL@@DE: Aus meines Herzens Grunde",
        "!!!OTL@EN: From the Depths of My Heart",
        "!!!SCT: BWV 269",
        "!!!ODT: 1736",
        "**kern", "4c", "*-",
        "!!!EED: Someone"
      ))
    end

    it "collects every composer in order" do
      expect(cited.composers).to eq ["Bach, Johann Sebastian", "Anonymous"]
    end

    it "falls back to the original-language title" do
      expect(cited.title).to eq "Aus meines Herzens Grunde"
    end

    it "prefers a plain title" do
      expect(document(lines("!!!OTL@@DE: Grunde", "!!!OTL: Heart", "**kern", "4c", "*-")).title).to eq "Heart"
    end

    it "collects the dates and catalog number" do
      expect([cited.composer_dates, cited.catalog_number, cited.date])
        .to eq ["1685/02/21/-1750/07/28/", "BWV 269", "1736"]
    end

    it "has no title without a title record" do
      expect(document(lines("**kern", "4c", "*-")).title).to be_nil
    end
  end

  describe "errors" do
    it "raises when there is no kern spine" do
      expect { document(lines("**dynam\t**text", "p\tla", "*-\t*-")) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /no \*\*kern spine \(line 1\)/)
    end

    it "raises when there are no spines at all" do
      expect { document("!!!OTL: Air") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /no \*\*kern spine/)
    end

    it "raises when a row's field count does not match the live spines" do
      expect { document(lines("**kern\t**kern", "4c\t4e\t4g", "*-\t*-")) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /Row has 3 fields but 2 spines are live \(line 2\)/)
    end

    it "checks field counts against the layout after a split" do
      expect { document(lines("**kern", "*^", "4c", "*-")) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /Row has 1 field but 2 spines are live \(line 3\)/)
    end

    it "raises when the final *- row is missing" do
      expect { document(lines("**kern", "4c", "!!!EED: Someone")) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /must end with a \*- row.*\(line 3\)/)
    end

    it "raises for a spine record after every spine ends" do
      expect { document(lines("**kern", "4c", "*-", "4d")) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /after every spine was terminated \(line 4\)/)
    end

    it "raises for a second exclusive interpretation row" do
      expect { document(lines("**kern", "**kern", "*-")) }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /Unexpected exclusive interpretation \(line 2\)/)
    end
  end
end
