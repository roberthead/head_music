require "spec_helper"

describe HeadMusic::Notation::Kern::LyricReader do
  def parse(text)
    HeadMusic::Notation::Kern.parse(text.gsub(/ {2,}/, "\t"))
  end

  def lyrics(voice, verse = 1)
    voice.voice_events.map { |voice_event| voice_event.syllable(verse)&.then { |syllable| [syllable.text, syllable.hyphen_after?] } }
  end

  describe "a sung voice with two verses" do
    subject(:flow) do
      parse(<<~KERN)
        **kern  **text  **silbe  **kern
        4c  Aus  From  4e
        4d  mei-  the  4f
        4e  -nes  _  4g
        4f  |  depths  4a
        4g  .  .  4b
        *-  *-  *-  *-
      KERN
    end

    let(:sung) { flow.parts.last.voices.first }

    it "attaches the first lyric spine to the kern spine on its left as verse 1" do
      expect(lyrics(sung)).to eq [["Aus", false], ["mei", true], ["nes", false], nil, nil]
    end

    it "reads the next lyric spine for the same kern spine as verse 2" do
      expect(lyrics(sung, 2)).to eq [["From", false], ["the", false], nil, ["depths", false], nil]
    end

    it "reads a lone | or _ as a held note of the verse it stands in" do
      expect([1, 2].map { |verse| sung.voice_events.map { |voice_event| voice_event.extends_syllable?(verse) } })
        .to eq [[false, false, false, true, false], [false, false, true, false, false]]
    end

    it "leaves the kern spine on the right unsung" do
      expect(flow.parts.first.voices.first.voice_events.none?(&:sung?)).to be true
    end
  end

  it "sings to the upper voice of a split spine" do
    flow = parse("**kern  **text\n*^  *\n2e  2c  la\n2f  2d  -la\n*v  *v  *\n*-  *-")
    expect(flow.voices.map { |voice| voice.voice_events.map(&:sung?) }).to eq [[true, true], [false, false]]
  end

  it "attaches a syllable to the whole of a tied note" do
    flow = parse("**kern  **text\n[2c  la\n2c]  .\n*-  *-")
    expect(flow.voices.first.voice_events.map { |voice_event| voice_event.syllable&.text }).to eq ["la"]
  end

  describe "extenders" do
    def holds(flow)
      flow.voices.first.voice_events.map { |voice_event| voice_event.extends_syllable? }
    end

    it "reads a trailing underscore as a line over the null rows after it, up to the next syllable" do
      flow = parse("**kern  **text\n4c  Lord_\n4d  .\n4e  .\n4f  praise\n*-  *-")
      expect([lyrics(flow.voices.first), holds(flow)]).to eq [[["Lord", false], nil, nil, ["praise", false]], [false, true, true, false]]
    end

    it "stops a line at a rest" do
      flow = parse("**kern  **text\n4c  Lord_\n4d  .\n4r  .\n4f  .\n*-  *-")
      expect(holds(flow)).to eq [false, true, false, false]
    end

    it "holds the null rows after a hyphenated syllable" do
      flow = parse("**kern  **text\n4c  Glo-\n2d  .\n4e  -ri-\n*-  *-")
      expect(holds(flow)).to eq [false, true, false]
    end

    it "reads a hyphenated lone underscore as a held note, not an empty syllable" do
      flow = parse("**kern  **text\n4c  Glo-\n4d  -_\n4e  -ri\n*-  *-")
      expect([lyrics(flow.voices.first), holds(flow)]).to eq [[["Glo", true], nil, ["ri", false]], [false, true, false]]
    end

    it "holds a line on past a lone underscore up to the next syllable" do
      flow = parse("**kern  **text\n4c  Lord_\n4d  _\n4e  .\n4f  praise\n*-  *-")
      expect(holds(flow)).to eq [false, true, true, false]
    end

    it "holds nothing after a word-final syllable with no underscore" do
      flow = parse("**kern  **text\n2c  Lord\n2d  .\n*-  *-")
      expect(holds(flow)).to eq [false, false]
    end

    it "skips a lone underscore with nothing before it to hold, or no note under it" do
      flow = parse("**kern  **text\n2c  _\n[2d  la\n2d]  _\n*-  *-")
      expect([lyrics(flow.voices.first), holds(flow)]).to eq [[nil, ["la", false]], [false, false]]
    end
  end

  describe "errors" do
    it "raises when a syllable falls under a null token" do
      expect { parse("**kern  **text\n2c  la\n.  la\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /syllable "la" in spine 2 has no note under it \(line 3\)/)
    end

    it "raises when a syllable falls under a rest" do
      expect { parse("**kern  **text\n2r  la\n*-  *-") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /no note under it/)
    end

    it "raises when a syllable falls under a tied note's continuation" do
      expect { parse("**kern  **text\n[2c  la\n2c]  la\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /no note under it \(line 3\)/)
    end

    it "raises when a lyric spine has no kern spine on its left" do
      expect { parse("**text  **kern\nla  1c\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /\*\*text spine must follow the \*\*kern spine.*\(line 2\)/)
    end
  end
end
