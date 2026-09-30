require "spec_helper"

describe HeadMusic::Notation::LilyPond::FlowBuilder do
  def build(source)
    tokens = HeadMusic::Notation::LilyPond::Lexer.new(source).tokens
    document = HeadMusic::Notation::LilyPond::DocumentReader.new(tokens).document
    described_class.new(document).flow
  end

  def voice_events(source)
    voice_events_of(build(source))
  end

  def voice_events_of(flow)
    flow.voices.flat_map { |voice| voice.voice_events.map(&:to_s) }
  end

  describe "identity" do
    it "seeds the name, composer, key, and meter" do
      flow = build(%(\\header { title = "Air" composer = "A." } { \\key g \\major \\time 3/4 c'2. }))
      expect([flow.name, flow.composer, flow.key_signature.to_s, flow.meter.to_s])
        .to eq ["Air", "A.", "1 sharp", "3/4"]
    end

    it "defaults to C major and 4/4, as LilyPond does" do
      flow = build("{ c'1 }")
      expect([flow.key_signature.to_s, flow.meter.to_s]).to eq ["no sharps or flats", "4/4"]
    end

    it "defaults the name" do
      expect(build("{ c'1 }").name).to eq "Composition"
    end

    it "raises when there is no music" do
      expect { build("{ }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /contains no music/)
    end
  end

  describe "voice events" do
    it "places notes and rests consecutively" do
      expect(voice_events("{ c'4 r4 e'2 }")).to eq ["quarter C4 at 1:1:000", "quarter rest at 1:2:000", "half E4 at 1:3:000"]
    end

    it "keeps rests distinct from notes" do
      voice = build("{ c'4 r4 }").voices.first
      expect([voice.notes.length, voice.rest_events.length]).to eq [1, 1]
    end

    it "places a chord as one voice event" do
      voice_event = build("{ <c' e' g'>1 }").voices.first.voice_events.first
      expect([voice_event.chord?, voice_event.pitches.map(&:to_s)]).to eq [true, %w[C4 E4 G4]]
    end

    it "carries a tied value into one voice event" do
      expect(voice_events("{ c'2~ c'8 d'8 e'4 }").first).to eq "half tied to eighth C4 at 1:1:000"
    end

    it "rolls into the next bar" do
      expect(voice_events("{ c'1 d'1 }").last).to eq "whole D4 at 2:1:000"
    end

    it "gives each stream its own voice with its role" do
      flow = build(%(<< \\new Staff \\with { instrumentName = "A" } { c'1 } \\new Staff { d'1 } >>))
      expect(flow.voices.map { |voice| [voice.role, voice.pitches.map(&:to_s)] }).to eq [["A", %w[C4]], [nil, %w[D4]]]
    end

    it "builds an empty voice for an empty staff" do
      expect(build("\\new Staff { }").voices.first.voice_events).to be_empty
    end
  end

  describe "bar checks" do
    it "passes at the start of a bar" do
      expect(voice_events("{ c'2 d'2 | e'1 | }").last).to eq "whole E4 at 2:1:000"
    end

    it "passes at the very start" do
      expect(voice_events("{ | c'1 }")).to eq ["whole C4 at 1:1:000"]
    end

    it "passes across a meter change" do
      expect(voice_events("{ c'1 | \\time 3/4 d'2. | e'4 }").last).to eq "quarter E4 at 3:1:000"
    end

    it "raises for an underfilled bar with the elapsed fraction" do
      expect { build("{ c'2 d'4 | e'1 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Bar check failed at: 3\/4 in bar 1 \(line 1\)/)
    end

    it "raises for an overfilled bar in the bar it spilled into" do
      expect { build("{ c'1 d'4 | e'1 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Bar check failed at: 1\/4 in bar 2/)
    end

    it "passes inside a note tied across the barline" do
      expect(voice_events("{ c'2 d'2~ | d'4 e'2. | }")).to eq [
        "half C4 at 1:1:000", "half tied to quarter D4 at 1:3:000", "dotted half E4 at 2:2:000"
      ]
    end

    it "raises for a bar check inside a tied note that is not at a barline, at the check's line" do
      expect { build("{ c'4~\n| c'2. }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Bar check failed at: 1\/4 in bar 1 \(line 2\)/)
    end

    it "applies a key change written between the halves of a tied note at its barline" do
      flow = build("{ c'2 d'2~ | \\key g \\major d'2 e'2 | }")
      expect([flow.key_signature_changes.keys, flow.voices.first.voice_events.length]).to eq [[2], 3]
    end

    it "applies a meter change written between the halves of a tied note at its barline" do
      flow = build("{ c'2 d'2~ | \\time 3/4 d'2 e'4 | f'2. | }")
      expect([flow.meter_changes.keys, voice_events_of(flow).last]).to eq [[2], "dotted half F4 at 3:1:000"]
    end

    it "applies a change at a barline inside a tied note even without a bar check" do
      expect(build("{ c'2 d'2~ \\key g \\major d'2 e'2 }").key_signature_changes.keys).to eq [2]
    end

    it "raises for a change in the middle of a bar inside a tied note, at the change's line" do
      expect { build("{ c'2~\n\\key g \\major c'2 }") }.to raise_error(
        HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /\\key in the middle of a bar is not supported \(line 2\)/
      )
    end

    it "reports a partial count in ticks" do
      expect { build("{ c'8 | }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /failed at: 1\/8 in bar 1/)
    end
  end

  describe "whole-bar rests" do
    it "places a whole rest in 4/4" do
      expect(voice_events("{ R1*4/4 c'1 }").first).to eq "whole rest at 1:1:000"
    end

    it "places a dotted half rest in 3/4" do
      expect(voice_events("{ \\time 3/4 R1*3/4 }").first).to eq "dotted half rest at 1:1:000"
    end

    it "places a tied rest in 5/4" do
      expect(voice_events("{ \\time 5/4 R1*5/4 }").first).to eq "whole tied to quarter rest at 1:1:000"
    end

    it "accepts a bare R1 in 4/4" do
      expect(voice_events("{ R1 }").first).to eq "whole rest at 1:1:000"
    end

    it "raises for a multi-bar rest" do
      expect { build("{ R1*2 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Multi-bar rests are not yet supported \(2 whole notes in 4\/4\)/)
    end

    it "raises for a rest that does not fill the bar" do
      expect { build("{ R1*3/4 }") }.to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Multi-bar rests/)
    end

    it "raises for a whole-bar rest starting mid-bar" do
      expect { build("{ c'4 R1*4/4 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /must start a bar/)
    end
  end

  describe "key and meter changes" do
    it "applies a mid-piece key change to the bar" do
      flow = build("{ c'1 | \\key d \\major d'1 | }")
      expect([flow.key_signature_at(1).to_s, flow.key_signature_at(2).to_s]).to eq ["no sharps or flats", "2 sharps"]
    end

    it "applies a mid-piece meter change to the bar" do
      flow = build("{ c'1 | \\time 3/4 d'2. | }")
      expect([flow.meter_at(1).to_s, flow.meter_at(2).to_s]).to eq ["4/4", "3/4"]
    end

    it "treats the same change in a second voice as a no-op" do
      source = "<< \\new Staff { c'1 | \\key d \\major \\time 3/4 d'2. | } \\new Staff { c1 | \\key d \\major \\time 3/4 d2. | } >>"
      flow = build(source)
      expect([flow.key_signature_at(2).to_s, flow.meter_at(2).to_s]).to eq ["2 sharps", "3/4"]
    end

    it "treats a restated key as a no-op that leaves the key in force" do
      flow = build("{ \\key d \\major c'1 | \\key d \\major d'1 | }")
      expect(flow.key_signature_at(2).to_s).to eq "2 sharps"
    end

    it "raises for a conflicting key at bar one" do
      expect { build("<< \\new Staff { \\key g \\major c'1 } \\new Staff { \\key d \\major c1 } >>") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Conflicting \\key at bar 1/)
    end

    it "raises for a conflicting meter at bar one" do
      expect { build("<< \\new Staff { \\time 4/4 c'1 } \\new Staff { \\time 3/4 c2. } >>") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Conflicting \\time at bar 1/)
    end

    it "raises for conflicting changes at a later bar" do
      source = "<< \\new Staff { c'1 | \\key d \\major d'1 } \\new Staff { c1 | \\key g \\major d1 } >>"
      expect { build(source) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Conflicting \\key at bar 2/)
    end

    it "raises for conflicting meters at a later bar" do
      source = "<< \\new Staff { c'1 | \\time 3/4 d'2. } \\new Staff { c1 | \\time 2/4 d2 } >>"
      expect { build(source) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Conflicting \\time at bar 2/)
    end

    it "applies a change from one staff to the voices that do not restate it" do
      source = "<< \\new Staff { c'1 c'1 c'1 } \\new Staff { \\time 4/4 c1 | \\time 3/4 c4 c c | c4 c c } >>"
      expect(build(source).voices.first.voice_events.map(&:position).map(&:to_s)).to eq %w[1:1:000 2:1:000 3:2:000]
    end

    it "reads the same score the same way whichever staff carries the change" do
      plain = "\\new Staff { c'1 c'1 c'1 }"
      changing = "\\new Staff { \\time 4/4 c1 | \\time 3/4 c4 c c | c4 c c }"
      positions = ->(source) { build(source).voices.map { |voice| voice.voice_events.map { |p| p.position.to_s } } }
      expect(positions.call("<< #{plain} #{changing} >>")).to eq positions.call("<< #{changing} #{plain} >>").reverse
    end

    it "raises for a key change mid-bar" do
      expect { build("{ c'2 \\key d \\major d'2 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /\\key in the middle of a bar/)
    end

    it "raises for a meter change mid-bar" do
      expect { build("{ c'2 \\time 2/4 d'2 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /\\time in the middle of a bar/)
    end
  end

  describe "slurs and phrasing slurs" do
    def spans(music)
      build("{ \\time 4/4 #{music} }").voices.map { |voice| voice.spans.map(&:to_s) }
    end

    {
      "a slur" => ["c'4( d' e') f'", ["slur from 1:1:000 to 1:3:000"]],
      "a slur nested in a phrasing slur" => ["c'4\\( d'( e') f'\\)", ["phrase from 1:1:000 to 1:4:000", "slur from 1:2:000 to 1:3:000"]],
      "slurs named to overlap" => ["c'4\\=1( d'\\=2( e'\\=1) f'\\=2)", ["slur from 1:1:000 to 1:3:000", "slur from 1:2:000 to 1:4:000"]],
      "a named phrasing slur" => ["c'4\\=a\\( d' e'\\=a\\) f'", ["phrase from 1:1:000 to 1:3:000"]],
      "a slur with a direction" => ["c'4^( d' e'_) f'", ["slur from 1:1:000 to 1:3:000"]],
      "one slur ending where the next begins" => ["c'4( d' e')( f')", ["slur from 1:1:000 to 1:3:000", "slur from 1:3:000 to 1:4:000"]],
      "a slur closed on a tie's later link" => ["c'4( d' e'2~ | e'2) f'", ["slur from 1:1:000 to 1:3:000"]],
      "a phrasing slur ending on a rest" => ["c'4\\( d' r\\) f'", ["phrase from 1:1:000 to 1:3:000"]],
      "a slur on a chord" => ["<c' e'>4( d') e' f'", ["slur from 1:1:000 to 1:2:000"]]
    }.each do |description, (music, expected)|
      it "reads #{description}" do
        expect(spans(music)).to eq [expected]
      end
    end

    {
      "a slur ending on a rest" => "c'4( d' r) f'",
      "an unmatched close and an unclosed open" => "c'4 d') e'( f'"
    }.each do |description, music|
      it "drops #{description}" do
        expect(spans(music)).to eq [[]]
      end
    end

    it "ignores a second open while one is open, as LilyPond does" do
      expect(spans("c'4( d'( e') f'")).to eq [["slur from 1:1:000 to 1:3:000"]]
    end
  end

  describe "bar marks" do
    def bars(music)
      build(music).bars.map(&:to_h)
    end

    it "puts a mark at a bar's start on that bar" do
      expect(bars(%({ c'1 | \\mark "B" \\segnoMark 1 \\codaMark 1 d'1 | e'1 }))).to eq [
        {}, {"rehearsal_mark" => "B", "segno" => true, "coda" => true}, {}
      ]
    end

    it "puts a barline, Fine, To Coda, or jump at a bar's start on the bar before" do
      expect(bars(%({ c'1 \\fine \\jump "To Coda" \\jump "D.C." \\section | d'1 }))).to eq [
        {"barline" => "double", "fine" => true, "to_coda" => true, "jump" => {"kind" => "da_capo"}}, {}
      ]
    end

    it "keeps a final barline before the last bar" do
      expect(bars(%({ c'1 \\bar "|." d'1 }))).to eq [{"barline" => "final"}, {}]
    end

    it "reads the first of two coda marks as the To Coda of an al Coda jump" do
      expect(bars(%({ \\segnoMark 1 c'1 | \\codaMark 1 d'1 \\jump "D.S. al Coda" | \\codaMark 1 e'1 }))).to eq [
        {"segno" => true, "to_coda" => true}, {"jump" => {"kind" => "dal_segno", "to" => "coda"}}, {"coda" => true}
      ]
    end

    it "keeps two coda marks with no al Coda jump" do
      expect(bars(%({ c'1 | \\codaMark 1 d'1 | \\codaMark 1 e'1 }))).to eq [{}, {"coda" => true}, {"coda" => true}]
    end

    it "leaves the final barline at the end implied" do
      expect(bars(%({ c'1 d'1 \\bar "|." }))).to eq [{}, {}]
    end

    it "keeps a style other than final at the end" do
      expect(bars(%({ c'1 d'1 \\bar "||" }))).to eq [{}, {"barline" => "double"}]
    end

    it "closes a short final bar with the marks after its music" do
      expect(bars(%({ c'1 d'2 \\jump "D.C. al Fine" \\bar "|." }))).to eq [{}, {"jump" => {"kind" => "da_capo", "to" => "fine"}}]
    end

    it "drops marks in the middle of a bar, which have no bar to go on" do
      expect(bars(%({ c'2 \\mark "B" \\fine \\bar "||" d'2 | e'1 }))).to eq [{}, {}]
    end

    it "drops a mark at the start of a bar that holds no music" do
      flow = build(%({ c'1 | \\mark "B" \\segnoMark 1 }))
      expect([flow.bars.map(&:to_h), flow.last_marked_bar_number]).to eq [[{}], nil]
    end

    it "reads marks between the halves of a note tied across the barline" do
      expect(bars(%({ c'2 d'2~ | \\mark "B" \\bar "||" d'2 e'2 | f'1 }))).to eq [{"barline" => "double"}, {"rehearsal_mark" => "B"}, {}]
    end

    it "drops marks between the halves of a note tied within a bar" do
      expect(bars(%({ c'4~ \\mark "B" \\bar "||" c'4 d'2 | e'1 }))).to eq [{}, {}]
    end

    it "reads the same marks from every voice once" do
      source = %(<< \\new Staff { \\mark "A" c''1 \\bar "||" | d''1 } \\new Staff { \\mark "A" c1 \\bar "||" | d1 } >>)
      expect(bars(source)).to eq [{"rehearsal_mark" => "A", "barline" => "double"}, {}]
    end

    it "letters default marks in each voice alike" do
      source = %(<< \\new Staff { \\mark \\default c''1 | \\mark \\default d''1 } \\new Staff { \\mark \\default c1 | \\mark \\default d1 } >>)
      expect(bars(source)).to eq [{"rehearsal_mark" => "A"}, {"rehearsal_mark" => "B"}]
    end

    it "reads a mark from one voice alone" do
      source = %(<< \\new Staff { c''1 \\textEndMark "Fine" | d''1 } \\new Staff { c1 | d1 } >>)
      expect(bars(source)).to eq [{"fine" => true}, {}]
    end

    it "raises for voices that disagree about a bar" do
      source = %(<< \\new Staff { \\mark "A" c''1 } \\new Staff { \\mark "B" c1 } >>)
      expect { build(source) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Conflicting bar marks at bar 1/)
    end

    it "ignores the marks in a Dynamics context" do
      source = %(<< \\new Staff { c''1 | d''1 } \\new Dynamics { \\mark "A" s1 \\bar "||" | s1 } >>)
      expect(bars(source)).to eq [{}, {}]
    end
  end
end
