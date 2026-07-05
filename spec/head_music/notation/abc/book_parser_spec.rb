require "spec_helper"

describe HeadMusic::Notation::ABC::BookParser do
  def compositions_for(book)
    described_class.new(book).compositions
  end

  context "with a two-tune book" do
    let(:book) do
      <<~ABC
        X:1
        T:First Tune
        M:4/4
        L:1/8
        K:G
        GABc dedB|

        X:2
        T:Second Tune
        M:6/8
        L:1/8
        K:D
        DED FEF|
      ABC
    end

    let(:compositions) { compositions_for(book) }

    it "returns a composition per tune" do
      expect(compositions.map(&:class)).to eq [HeadMusic::Content::Composition] * 2
    end

    it "maps each tune's title" do
      expect(compositions.map(&:name)).to eq ["First Tune", "Second Tune"]
    end

    it "keys each tune independently" do
      expect(compositions.map(&:key_signature))
        .to eq [HeadMusic::Rudiment::KeySignature.get("G major"), HeadMusic::Rudiment::KeySignature.get("D major")]
    end

    it "places each tune's notes in its own composition" do
      expect(compositions.map { |composition| composition.voices.first.placements.length }).to eq [8, 6]
    end
  end

  it "returns a one-element array for a single tune" do
    expect(compositions_for("X:1\nK:C\nCDEF|\n").length).to eq 1
  end

  it "tolerates multiple blank lines between tunes" do
    book = "X:1\nK:C\nCDEF|\n\n\n\nX:2\nK:C\nGABc|\n"
    expect(compositions_for(book).length).to eq 2
  end

  it "skips comment-only paragraphs" do
    book = "% a tune book\n\nX:1\nK:C\nCDEF|\n\n% between tunes\n\nX:2\nK:C\nGABc|\n"
    expect(compositions_for(book).length).to eq 2
  end

  it "raises for blank input" do
    expect { compositions_for("  \n\n") }
      .to raise_error(HeadMusic::Notation::ABC::ParseError, /blank/)
  end

  it "raises when the input contains only comments" do
    expect { compositions_for("% nothing here\n\n% or here\n") }
      .to raise_error(HeadMusic::Notation::ABC::ParseError, /No tunes found/)
  end

  it "raises when a paragraph does not begin with an X: field" do
    book = "X:1\nK:C\nCDEF|\n\nsome stray text\n"
    expect { compositions_for(book) }
      .to raise_error(HeadMusic::Notation::ABC::ParseError, /X: field.*line 5/)
  end

  it "reports book-relative line numbers for an error inside a later tune" do
    book = "X:1\nK:C\nCDEF|\n\nX:2\nK:C\nGA&B|\n"
    expect { compositions_for(book) }
      .to raise_error(HeadMusic::Notation::ABC::ParseError, /"&".*line 7/)
  end

  it "reports book-relative line numbers for a header error inside a later tune" do
    book = "X:1\nK:C\nCDEF|\n\nX:2\nT:No Key\nGABc|\n\nX:3\nK:C\nCDEF|\n"
    expect { compositions_for(book) }
      .to raise_error(HeadMusic::Notation::ABC::ParseError, /K:.*line 7/)
  end
end
