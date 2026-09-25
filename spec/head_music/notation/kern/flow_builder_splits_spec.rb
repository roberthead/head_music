require "spec_helper"

describe HeadMusic::Notation::Kern::FlowBuilder do
  def parse(text)
    HeadMusic::Notation::Kern.parse(text.gsub(/ {2,}/, "\t"))
  end

  def placements(voice)
    voice.placements.map(&:to_s)
  end

  describe "a split in the middle of a bar, a join, and a re-split" do
    subject(:flow) do
      parse(<<~KERN)
        **kern
        *M4/4
        =1
        2c
        *^
        2e  4g
        .  4a
        *v  *v
        =2
        2d
        *^
        2f  2b
        *v  *v
        =3
        1c
        *-
      KERN
    end

    let(:voices) { flow.parts.first.voices }

    it "keeps both sub-spines in one part" do
      expect([flow.parts.length, voices.length]).to eq [1, 2]
    end

    it "continues the existing voice in the left sub-spine" do
      expect(placements(voices.first))
        .to eq ["half C4 at 1:1:000", "half E4 at 1:3:000", "half D4 at 2:1:000", "half F4 at 2:3:000", "whole C4 at 3:1:000"]
    end

    it "pads the new voice to the whole flow, and reuses it across its dormant stretch" do
      expect(placements(voices.last))
        .to eq ["half rest at 1:1:000", "quarter G4 at 1:3:000", "quarter A4 at 1:4:000", "half rest at 2:1:000", "half B4 at 2:3:000", "whole rest at 3:1:000"]
    end

    it "leaves every voice continuous" do
      expect(voices.map(&:first_gap)).to eq [nil, nil]
    end
  end

  it "pads a dormant stretch that spans whole bars with a rest in each bar" do
    flow = parse("**kern\n*M2/4\n=1\n*^\n2c  2e\n*v  *v\n=2\n2d\n=3\n*^\n2c  2e\n*v  *v\n*-")
    expect(placements(flow.voices.last)).to eq ["half E4 at 1:1:000", "half rest at 2:1:000", "half E4 at 3:1:000"]
  end

  it "lets a split's new sub-spine enter while the left one holds its note" do
    flow = parse("**kern  **kern\n*M2/4  *M2/4\n=1  =1\n2c  4g\n*^  *\n.  4e  4a\n*v  *v  *\n=2  =2\n2c  2g\n*-  *-")
    expect(placements(flow.parts.last.voices.last)).to eq ["quarter rest at 1:1:000", "quarter E4 at 1:2:000", "half rest at 2:1:000"]
  end

  it "accepts a restated *part on the sub-spines of a split in the middle of the piece" do
    source = "**kern\n*part1\n*M2/4\n=1\n2c\n=2\n*^\n4c  4e\n*part1  *part1\n4c  4e\n*v  *v\n*-"
    expect(parse(source).voices.length).to eq 2
  end

  it "reads a split before the music as two voices on one staff" do
    flow = parse("**kern\n*clefG2\n*^\n1e  1c\n*v  *v\n*-")
    expect(flow.parts.map { |part| [part.staff_system.length, part.voices.map { |voice| voice.pitches.first.to_s }] })
      .to eq [[1, %w[E4 C4]]]
  end

  it "puts the new voice on its spine's staff" do
    flow = parse("**kern  **kern\n*part1  *part1\n*staff2  *staff1\n1C  1c\n*^  *\n1C  2E  2e\n.  2G  2g\n*-  *-  *-")
    lower = flow.parts.first.voices.last
    expect([lower.pitches.map(&:to_s), lower.staff.equal?(flow.parts.first.staff_system.staves.last)]).to eq [%w[E3 G3], true]
  end

  describe "an exchange" do
    subject(:flow) { parse("**kern  **kern\n1c  1e\n*x  *x\n1C  1g\n*-  *-") }

    it "keeps each spine's voice" do
      expect(flow.parts.map { |part| part.voices.first.pitches.map(&:to_s) }).to eq [%w[E4 C3], %w[C4 G4]]
    end
  end

  it "ends a sub-spine's voice where it ends, and wakes it at a later split" do
    flow = parse("**kern\n*M2/4\n=1\n*^\n2c  2e\n*  *-\n=2\n4d\n*^\n4d  4f\n*v  *v\n*-")
    expect([flow.voices.length, placements(flow.voices.last)])
      .to eq [2, ["half E4 at 1:1:000", "quarter rest at 2:1:000", "quarter F4 at 2:2:000"]]
  end

  it "starts a new voice when a dormant one is still sounding" do
    flow = parse("**kern\n*M2/4\n=1\n*^\n4c  2e\n*v  *v\n8d\n*^\n8d  8f\n*v  *v\n*-")
    expect(flow.voices.map { |voice| voice.pitches.map(&:to_s) }).to eq [%w[C4 D4 D4], %w[E4], %w[F4]]
  end

  it "follows splits beside a skipped spine that splits too" do
    flow = parse("**kern  **dynam\n1c  p\n*^  *^\n2c  2e  f  .\n2d  2g  .  p\n*v  *v  *  *\n*  *v  *v\n1c  .\n*-  *-")
    expect(flow.voices.map { |voice| voice.pitches.map(&:to_s) }).to eq [%w[C4 C4 D4 C4], %w[E4 G4]]
  end

  it "follows splits beside a lyric spine" do
    flow = parse("**kern  **text\n1c  la\n*^  *\n2c  2e  la\n2d  2g  .\n*v  *v  *\n*-  *-")
    expect(flow.voices.length).to eq 2
  end

  describe "errors" do
    it "raises an unsupported-feature error for a join across staves" do
      source = "**kern  **kern\n*part1  *part1\n*staff2  *staff1\n1C  1c\n*v  *v\n*-"
      expect { parse(source) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /different parts or staves.*\(line 5\)/)
    end

    it "raises an unsupported-feature error for a join across parts" do
      expect { parse("**kern  **kern\n1C  1c\n*v  *v\n1C\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /different parts or staves/)
    end

    it "raises for a lone *v" do
      expect { parse("**kern\n*^\n1c  1e\n*v  *\n1c  1e\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /\*v must join two or more adjacent spines \(line 4\)/)
    end

    it "raises an unsupported-feature error for a split in a lyric spine" do
      expect { parse("**kern  **text\n1c  la\n*  *^\n1c  la  .\n*-  *-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Splitting a \*\*text spine/)
    end

    it "raises an unsupported-feature error for a sub-spine that changes its *part in the middle of the piece" do
      source = "**kern\n*part1\n*M2/4\n=1\n2c\n=2\n*^\n4c  4e\n*part1  *part2\n4c  4e\n*v  *v\n*-"
      expect { parse(source) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Changing \*part2 .*\(line 9\)/)
    end

    it "raises an unsupported-feature error for *+" do
      expect { parse("**kern\n1c\n*+\n") }.to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /\*\+/)
    end

    it "fuses ties within sub-spines" do
      expect { parse("**kern\n*^\n[1c  [1e\n1c]  1e]\n*^  *\n1c  1e  1g\n*  *v  *v\n[1c  1e\n1c]  1e\n*v  *v\n*-") }
        .not_to raise_error
    end

    it "raises when a joined sub-spine leaves a tie open" do
      expect { parse("**kern\n*^\n1c  [1e\n*v  *v\n1c\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /tie is never closed \(line 3\)/)
    end
  end
end
