require "spec_helper"

describe HeadMusic::Notation::Kern::Lexer do
  def records(source)
    described_class.new(source).records
  end

  def kinds(source)
    records(source).map(&:kind)
  end

  let(:source) do
    [
      "!!!!SEGMENT: example.krn",
      "!!!COM: Bach, Johann Sebastian",
      "!! a global comment",
      "**kern\t**kern",
      "*M4/4\t*M4/4",
      "!\t! local",
      "=1\t=1",
      "4c\t4e",
      "*-\t*-"
    ].join("\n")
  end

  describe "classification" do
    it "classifies each kind of record" do
      expect(kinds(source)).to eq %i[
        universal reference global_comment exclusive interpretation local_comment barline data interpretation
      ]
    end

    it "splits spine records on tabs" do
      expect(records(source).last(2).first.fields).to eq %w[4c 4e]
    end

    it "keeps a global record whole" do
      expect(records(source)[1].fields).to eq ["!!!COM: Bach, Johann Sebastian"]
    end

    it "numbers records by their line in the file" do
      expect(records(source).map(&:line)).to eq (1..9).to_a
    end

    it "reads a reference record's key and value" do
      record = records(source)[1]
      expect([record.reference_key, record.reference_value]).to eq ["COM", "Bach, Johann Sebastian"]
    end

    it "gives no reference key for a universal record" do
      expect(records(source).first.reference_key).to be_nil
    end
  end

  describe "line endings" do
    it "strips carriage returns" do
      expect(records("**kern\r\n4c\r\n*-\r\n").map(&:fields)).to eq [["**kern"], ["4c"], ["*-"]]
    end

    it "skips blank lines, keeping the numbering of the others" do
      expect(records("**kern\n\n4c\n*-\n").map(&:line)).to eq [1, 3, 4]
    end

    it "ignores a byte order mark" do
      expect(kinds("\uFEFF**kern\n*-")).to eq %i[exclusive interpretation]
    end
  end

  describe "errors" do
    it "raises for input that is not valid UTF-8" do
      latin1 = "!!!COM: Josquin des Pr\xE9s\n**kern\n*-".dup.force_encoding(Encoding::UTF_8)
      expect { records(latin1) }.to raise_error(HeadMusic::Notation::Kern::ParseError, /not valid UTF-8 \(line 1\)/)
    end

    it "raises for input tagged with another encoding that is not valid UTF-8" do
      latin1 = "**kern\n4c\xE9\n*-".dup.force_encoding(Encoding::ASCII_8BIT)
      expect { records(latin1) }.to raise_error(HeadMusic::Notation::Kern::ParseError, /not valid UTF-8 \(line 2\)/)
    end

    it "raises for an empty field, naming the line" do
      expect { records("**kern\t**kern\n4c\t\n*-\t*-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /Empty field in column 2 \(line 2\)/)
    end

    it "raises for data before the exclusive interpretations" do
      expect { records("!!!OTL: Air\n4c\n**kern\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /must follow an exclusive interpretation.*\(line 2\)/)
    end

    it "raises for a row that mixes kinds of record" do
      expect { records("**kern\t**kern\n4c\t*\n*-\t*-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /"\*" does not match its row \(line 2\)/)
    end
  end
end
