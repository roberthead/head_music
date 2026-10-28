require "spec_helper"

describe HeadMusic::Notation::MusicXML::LyricReader do
  def lyric(text, number: "1", syllabic: nil)
    number_attribute = number && %( number="#{number}")
    %(<lyric#{number_attribute}>#{syllabic && "<syllabic>#{syllabic}</syllabic>"}<text>#{text}</text></lyric>)
  end

  def sung(pitch, duration, type, *lyrics, **options)
    note_xml(pitch, duration, type, after: lyrics.join, **options)
  end

  def parse(*measures)
    parse_musicxml_flow(musicxml_measures(*measures))
  end

  def syllables(flow)
    flow.voices.flat_map do |voice|
      voice.voice_events.flat_map do |voice_event|
        voice_event.syllables.values.map { |syllable| [voice_event.position.to_s, syllable.verse, syllable.text, syllable.hyphen_after?] }
      end
    end
  end

  it "sings each verse on its note event, hyphenating begin and middle syllables" do
    first = sung("C4", 1, "quarter", lyric("Ky", syllabic: "begin"), lyric("A", number: "2", syllabic: "single"))
    second = sung("D4", 1, "quarter", lyric("ri", syllabic: "middle"), lyric("men", number: "2", syllabic: "single"))
    flow = parse(first + second + sung("E4", 2, "half", lyric("e", syllabic: "end")))
    expect(syllables(flow).map { |_position, verse, text, hyphen| "#{verse}#{text}#{"-" if hyphen}" }).to eq %w[1Ky- 2A 1ri- 2men 1e]
  end

  it "takes a lyric with no number as verse 1" do
    flow = parse(sung("C4", 4, "whole", lyric("la", number: nil)))
    expect(syllables(flow)).to eq [["1:1:000", 1, "la", false]]
  end

  it "ranks a part's verses by first appearance when a number is not an integer" do
    flow = parse(
      sung("C4", 2, "half", lyric("b", number: "chorus"), lyric("a", number: "1")) +
        sung("D4", 2, "half", lyric("c", number: "1"), lyric("d", number: "verse"))
    )
    expect(syllables(flow)).to eq [["1:1:000", 1, "b", false], ["1:1:000", 2, "a", false], ["1:3:000", 2, "c", false], ["1:3:000", 3, "d", false]]
  end

  it "ranks each part's verses on its own" do
    flow = parse_musicxml_flow(musicxml_document([sung("C4", 4, "whole", lyric("x", number: "a"))], [sung("C4", 4, "whole", lyric("y", number: "3"))]))
    expect(syllables(flow)).to eq [["1:1:000", 1, "x", false], ["1:1:000", 3, "y", false]]
  end

  it "joins an elision's text pieces with its own text, or a tie when it is empty" do
    flow = parse(
      sung("C4", 2, "half", "<lyric><syllabic>single</syllabic><text>di</text><elision>_</elision><syllabic>begin</syllabic><text>a</text></lyric>") +
        sung("D4", 2, "half", "<lyric><text>e</text><elision/><text>o</text></lyric>")
    )
    expect(syllables(flow)).to eq [["1:1:000", 1, "di_a", true], ["1:3:000", 1, "e‿o", false]]
  end

  it "keeps the first syllable for a verse, as on a chord's tones" do
    flow = parse(sung("C4", 4, "whole", lyric("one")) + sung("E4", 4, "whole", lyric("two"), chord: true))
    expect(syllables(flow)).to eq [["1:1:000", 1, "one", false]]
  end

  it "skips lyrics on rests, grace notes, and a tie's later links, and lyrics with no text" do
    grace = "<note><grace/>#{pitch_xml("D5")}<type>16th</type>#{lyric("grace")}</note>"
    first_bar = rest_xml(1, "quarter", after: lyric("rest")) + grace + sung("C4", 3, "half", lyric("held"), dots: 1, inside: %(<tie type="start"/>))
    flow = parse(first_bar, sung("C4", 4, "whole", lyric("again"), "<lyric><extend/></lyric>", inside: %(<tie type="stop"/>)))
    expect(syllables(flow)).to eq [["1:2:000", 1, "held", false]]
  end

  describe "extenders" do
    def held(text, extend: nil, number: "1")
      type = extend && %( type="#{extend}")
      text ? lyric(text, number: number).sub("</lyric>", "<extend#{type}/></lyric>") : %(<lyric number="#{number}"><extend#{type}/></lyric>)
    end

    def holds(flow, verse = 1)
      flow.voices.first.voice_events.map { |voice_event| voice_event.extends_syllable?(verse) }
    end

    it "holds the notes an <extend> continues and stops" do
      flow = parse(
        sung("C4", 1, "quarter", held("Lord", extend: "start")) + sung("D4", 1, "quarter", held(nil, extend: "continue")) +
          sung("E4", 1, "quarter", held(nil, extend: "stop")) + sung("F4", 1, "quarter")
      )
      expect(holds(flow)).to eq [false, true, true, false]
    end

    it "holds a note whose lyric is an <extend> with no type, as older files write" do
      flow = parse(sung("C4", 2, "half", held("Lord")) + sung("D4", 2, "half", held(nil)))
      expect(holds(flow)).to eq [false, true]
    end

    it "holds the notes after a line start with no stop up to the next sung note or rest" do
      flow = parse(
        sung("C4", 1, "quarter", held("Lord", extend: "start")) + sung("D4", 1, "quarter") + rest_xml(1, "quarter") + sung("F4", 1, "quarter")
      )
      expect(holds(flow)).to eq [false, true, false, false]
    end

    it "holds the notes after a hyphenated syllable up to the next one" do
      flow = parse(sung("C4", 1, "quarter", lyric("Glo", syllabic: "begin")) + sung("D4", 2, "half") + sung("E4", 1, "quarter", lyric("ri", syllabic: "middle")))
      expect(holds(flow)).to eq [false, true, false]
    end

    it "holds each verse on its own" do
      flow = parse(sung("C4", 2, "half", held("Lord", extend: "start"), lyric("O", number: "2")) + sung("D4", 2, "half", held(nil, extend: "stop")))
      expect([holds(flow, 1), holds(flow, 2)]).to eq [[false, true], [false, false]]
    end

    it "skips a held note with nothing before it to hold" do
      flow = parse(sung("C4", 2, "half") + sung("D4", 2, "half", held(nil, extend: "stop")))
      expect(holds(flow)).to eq [false, false]
    end

    it "never takes an <extend> for a syllable" do
      flow = parse(sung("C4", 2, "half", held("Lord", extend: "start")) + sung("D4", 2, "half", held(nil, extend: "stop")))
      expect(syllables(flow)).to eq [["1:1:000", 1, "Lord", false]]
    end
  end

  describe "round trips" do
    def round_trip(flow)
      HeadMusic::Notation::MusicXML.parse(HeadMusic::Notation::MusicXML.render(flow))
    end

    let(:two_verses) do
      HeadMusic::Content::Flow.new(name: "Two Verses", meter: "3/4").tap do |flow|
        voice = flow.add_voice
        voice.place("1:1", :quarter, %w[C4 E4]).sing("Glo", hyphen_after: true).sing("Peace", verse: 2)
        voice.place("1:2", :half, "D4").sing("ri", hyphen_after: true)
        voice.place("2:1", :whole, "E4").sing("a").sing("on", verse: 2)
        voice.place("3:2", :quarter, "D4")
        voice.place("3:3", :quarter, "F4").sing("earth", verse: 2)
      end
    end

    it "brings back every syllable of a two-verse song with a melisma, a chord, and a tie" do
      expect(syllables(round_trip(two_verses))).to eq syllables(two_verses)
    end

    it "brings back LilyPondFixtures.song" do
      flow = LilyPondFixtures.song
      expect(syllables(round_trip(flow))).to eq syllables(flow)
    end
  end
end
