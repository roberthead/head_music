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

  describe "spacers" do
    it "adds no event for a spacer that ends the voice" do
      expect(voice_events("{ c'4 d'4 e'4 s4 | }")).to eq ["quarter C4 at 1:1:000", "quarter D4 at 1:2:000", "quarter E4 at 1:3:000"]
    end

    it "places a level on a spacer that ends the voice at the spacer's position" do
      expect(build("{ c'4 d'4 e'4 s4\\f | }").voices.first.dynamic_events.map(&:to_s)).to eq ["f at 1:4:000"]
    end

    it "reads a spacer that music follows as a rest" do
      expect(voice_events("{ s4\\p c'4 s4*2 | d'1 }")).to eq [
        "quarter rest at 1:1:000", "quarter C4 at 1:2:000", "half rest at 1:3:000", "whole D4 at 2:1:000"
      ]
    end

    it "reads spacers that reach a bar after the music's last as rests, so their level stays in written bars" do
      flow = build("{ c'2. s4 | s1\\f | }")
      expect([voice_events("{ c'2. s4 | s1\\f | }"), flow.voices.first.dynamic_events.map(&:to_s)])
        .to eq [["dotted half C4 at 1:1:000", "quarter rest at 1:4:000", "whole rest at 2:1:000"], ["f at 2:1:000"]]
    end

    it "keeps the level on a spacer that music follows" do
      expect(build("{ c'4 s4\\p e'2 }").voices.first.dynamic_events.map(&:to_s)).to eq ["p at 1:2:000"]
    end

    it "checks a bar after a spacer that ends the voice" do
      expect { build("{ c'4 s2 | }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /failed at: 3\/4 in bar 1/)
    end

    it "measures a spacer under a meter another staff changes" do
      source = %(<< \\new Staff { c'2 s2 s2 | d'4 } \\new Staff { c'1 | \\time 2/4 e'2 } >>)
      expect(build(source).voices.first.voice_events.map(&:to_s).last).to eq "quarter D4 at 3:1:000"
    end

    it "raises for a spacer that music follows when no rest can stand for it" do
      expect { build("{ s4*5/3 c'4 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /spacer of 5\/12 whole notes has no rest/)
    end
  end

  describe "\\after" do
    def levels(source)
      build(source).voices.first.dynamic_events.map(&:to_s)
    end

    it "places a level part way into a note, leaving the note whole" do
      flow = build("{ \\after 4 \\p c'2. d'4 | }")
      expect([voice_events_of(flow), flow.voices.first.dynamic_events.map(&:to_s)])
        .to eq [["dotted half C4 at 1:1:000", "quarter D4 at 1:4:000"], ["p at 1:2:000"]]
    end

    it "reads a dotted offset" do
      expect(levels("{ c'4 \\after 4. \\p c'2. | }")).to eq ["p at 1:3:480"]
    end

    it "reads a multiplied offset" do
      expect(levels("{ \\after 4*3/5 \\p c'1 | }")).to eq ["p at 1:1:576"]
    end

    it "measures nested offsets from the same note" do
      expect(levels("{ \\after 4 \\p \\after 2 \\f c'1 | }")).to eq ["p at 1:2:000", "f at 1:3:000"]
    end

    it "places a level on the second link of a tie from where the link starts" do
      flow = build("{ c'2~ \\after 4 \\p c'2 | }")
      expect([voice_events_of(flow), flow.voices.first.dynamic_events.map(&:to_s)])
        .to eq [["half tied to half C4 at 1:1:000"], ["p at 1:4:000"]]
    end

    it "places a level on a link after a barline" do
      expect(levels("{ c'1~ | \\after 4 \\p c'2 d'2 | }")).to eq ["p at 2:2:000"]
    end

    it "measures from the start of a sequence" do
      expect(levels("{ \\after 2 \\mf { c'4 d'4 e'2 } | }")).to eq ["mf at 1:3:000"]
    end

    it "keeps the carried duration of the music it wraps" do
      expect(voice_events("{ c'8 \\after 4 \\p c' d'4 }")).to eq ["eighth C4 at 1:1:000", "eighth C4 at 1:1:480", "quarter D4 at 1:2:000"]
    end

    it "drops a mark that is not a level" do
      flow = build("{ \\after 8 -. c'4 \\after 8 \\sfz d'4 \\after 8 \\< e'2 }")
      expect([flow.voices.first.dynamic_events, flow.voices.first.note_events.flat_map(&:articulations)]).to eq [[], []]
      expect(flow.voices.first.note_events.map(&:note_dynamic)).to eq [nil, nil, nil]
    end

    {
      "{ \\after \\p c'1 }" => [HeadMusic::Notation::LilyPond::ParseError, /\\after expects a duration/],
      "{ \\after 4 c'1 }" => [HeadMusic::Notation::LilyPond::ParseError, /\\after expects a mark/],
      "{ \\after 4 \\p | c'1 }" => [HeadMusic::Notation::LilyPond::ParseError, /\\after expects music/],
      "{ \\after 4 \\startTextSpan c'1 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /"\\startTextSpan"/],
      "{ \\after 4 -1 c'1 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /"-"/],
      "{ \\after 4*1/7 \\p c'1 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /An \\after of 1\/28 whole notes falls between ticks/]
    }.each do |source, (error_class, message)|
      it "raises for #{source}" do
        expect { build(source) }.to raise_error(error_class, message)
      end
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

  describe "hairpins" do
    def hairpins(music)
      build("{ #{music} }").voices.first.spans.map(&:to_s)
    end

    {
      "a hairpin ended by \\!" => ["c'4\\< d' e' f'\\!", ["crescendo from 1:1:000 to 1:4:000"]],
      "a hairpin ended by a level" => ["c'4\\< d' e' f'\\f", ["crescendo from 1:1:000 to 1:4:000"]],
      "a hairpin ended by an accent" => ["c'4\\> d' e' f'\\sfz", ["diminuendo from 1:1:000 to 1:4:000"]],
      "a hairpin ended by the next" => ["c'4\\< d' e'\\> f' | g'1\\!", ["crescendo from 1:1:000 to 1:3:000", "diminuendo from 1:3:000 to 2:1:000"]],
      "an end before a start written after it" => ["c'4\\< d' e'\\mf\\> f' | g'1\\!", ["crescendo from 1:1:000 to 1:3:000", "diminuendo from 1:3:000 to 2:1:000"]],
      "an end before a start written before it" => ["c'4\\< d' e'\\>\\mf f' | g'1\\!", ["crescendo from 1:1:000 to 1:3:000", "diminuendo from 1:3:000 to 2:1:000"]],
      "an end on a tied note's later link" => ["c'4\\< d'2~ d'4\\! | e'1", ["crescendo from 1:1:000 to 1:4:000"]],
      "a start on a tied note's later link" => ["c'2~ c'4\\< d'4 | e'1\\!", ["crescendo from 1:3:000 to 2:1:000"]],
      "an end on a rest" => ["c'4\\< d' r\\! f'", ["crescendo from 1:1:000 to 1:3:000"]],
      "an end on a whole-bar rest" => ["c'1\\< | R1*4/4\\! | c'1", ["crescendo from 1:1:000 to 2:1:000"]],
      "an end on a spacer" => ["c'2\\< s4\\! c'4", ["crescendo from 1:1:000 to 1:3:000"]],
      "\\<\\! on one note, ended end first and so left open until a level" => ["c'4\\<\\! d'\\p e' f'", ["crescendo from 1:1:000 to 1:2:000"]],
      "\\cresc ended by a level" => ["c'4\\cresc d' e' f'\\f", ["crescendo from 1:1:000 to 1:4:000"]],
      "\\cresc ended by \\endcresc" => ["c'4\\cresc d' e'\\endcresc f'", ["crescendo from 1:1:000 to 1:3:000"]],
      "\\dim ended by \\enddim" => ["c'4\\dim d' e'\\enddim f'", ["diminuendo from 1:1:000 to 1:3:000"]],
      "\\decresc ended by \\enddecresc" => ["c'4\\decresc d' e'\\enddecresc f'", ["diminuendo from 1:1:000 to 1:3:000"]],
      "an end placed with \\after" => ["\\after 2 \\! c'1\\<", ["crescendo from 1:1:000 to 1:3:000"]],
      "a hairpin among styling commands" => ["\\crescTextCresc c'4\\< d' \\dimTextDim e' \\crescHairpin f'\\! \\dimHairpin", ["crescendo from 1:1:000 to 1:4:000"]],
      "an unterminated hairpin" => ["c'4\\< d' e' f'", []],
      "a stray \\!" => ["c'4 d'\\! e' f'", []],
      "\\<\\! on one note with nothing after" => ["c'4\\<\\! d' e' f'", []]
    }.each do |description, (music, expected)|
      it "reads #{description}" do
        expect(hairpins(music)).to eq expected
      end
    end

    it "keeps each voice's hairpins to itself" do
      flow = build(%(\\new Staff << \\new Voice { c''4\\< d'' e'' f''\\! } \\new Voice { c'4 d'\\f e'2 } >>))
      expect(flow.voices.map { |voice| voice.spans.map(&:to_s) }).to eq [["crescendo from 1:1:000 to 1:4:000"], []]
    end

    it "still places the levels that end hairpins" do
      expect(build("{ c'4\\< d' e'\\f\\> f' | g'1\\p }").voices.first.dynamic_events.map(&:to_s)).to eq ["f at 1:3:000", "p at 2:1:000"]
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
