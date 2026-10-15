require "spec_helper"

describe HeadMusic::Notation::LilyPond::TupletReader do
  def voice(source)
    HeadMusic::Notation::LilyPond.parse(source).voices.first
  end

  def events(source)
    voice(source).voice_events.map { |event| [event.position.to_s, event.rhythmic_value.to_s] }
  end

  def groups(source)
    voice(source).tuplets.map { |group| [group.from.to_s, group.to.to_s, group.ratio.to_s, group.unit.to_s] }
  end

  describe "\\tuplet n/d" do
    let(:source) { "{ \\tuplet 3/2 { c'8 d' e' } f'8 g'4. }" }

    it "gives the music inside the ratio" do
      expect(events(source)).to eq [
        ["1:1:000", "triplet eighth"], ["1:1:320", "triplet eighth"], ["1:1:640", "triplet eighth"],
        ["1:2:000", "eighth"], ["1:2:480", "dotted quarter"]
      ]
    end

    it "brackets it" do
      expect(groups(source)).to eq [["1:1:000", "1:2:000", "triplet", "eighth"]]
    end

    it "leaves no gap" do
      expect(voice(source).first_gap).to be_nil
    end
  end

  it "reads \\times d/n as the inverse fraction" do
    expect(groups("{ \\times 2/3 { c'4 d' e' } c'2 }")).to eq [["1:1:000", "1:3:000", "triplet", "quarter"]]
  end

  it "reads a single note as the music" do
    expect(groups("{ \\tuplet 3/2 c'4 \\tuplet 3/2 d'4 \\tuplet 3/2 e'4 f'2 }")).to eq [
      ["1:1:000", "1:1:640", "triplet", "quarter"], ["1:1:640", "1:2:320", "triplet", "quarter"], ["1:2:320", "1:3:000", "triplet", "quarter"]
    ]
  end

  it "keeps one bracket for six notes under 3/2, as LilyPond draws it" do
    expect(groups("{ \\tuplet 3/2 { c'8 d' e' f' g' a' } c'2 }")).to eq [["1:1:000", "1:3:000", "triplet", "quarter"]]
  end

  it "keeps the ratio as written" do
    expect(groups("{ \\tuplet 6/4 { c'16 d' e' f' g' a' } c'2. }")).to eq [["1:1:000", "1:2:000", "6:4", "sixteenth"]]
  end

  it "rounds a septuplet's onsets from its start, so the bracket ends exactly" do
    source = "{ \\tuplet 7/4 { c'16 d' e' f' g' a' b' } c'2. }"
    expect(events(source).map(&:first)).to eq %w[1:1:000 1:1:137:034 1:1:274:069 1:1:411:103 1:1:548:137 1:1:685:171 1:1:822:206 1:2:000]
    expect(groups(source)).to eq [["1:1:000", "1:2:000", "7:4", "sixteenth"]]
  end

  it "carries the written duration on outside the tuplet" do
    expect(events("{ \\tuplet 3/2 { c'8 d' e' } f' g'4. }")[3]).to eq ["1:2:000", "eighth"]
  end

  describe "a span" do
    it "starts a new bracket each span, with a short one for the remainder" do
      expect(groups("{ \\tuplet 3/2 4 { c'8 d' e' f' g' a' b' c'' } d''4 }")).to eq [
        ["1:1:000", "1:2:000", "triplet", "eighth"], ["1:2:000", "1:3:000", "triplet", "eighth"], ["1:3:000", "1:3:640", "triplet", "eighth"]
      ]
    end

    it "reads a dotted span" do
      expect(groups("{ \\time 6/8 \\tuplet 4/3 4. { c'8 d' e' f' g' a' b' c'' } }").map(&:first)).to eq ["1:1:000", "1:4:000"]
    end

    it "comes from \\tupletSpan until \\tupletSpan \\default" do
      source = "{ \\tupletSpan 4 \\tuplet 3/2 { c'8 d' e' f' g' a' } \\tupletSpan \\default \\tuplet 3/2 { c'8 d' e' f' g' a' } }"
      expect(groups(source).map { |from, to| [from, to] }).to eq [
        ["1:1:000", "1:2:000"], ["1:2:000", "1:3:000"], ["1:3:000", "2:1:000"]
      ]
    end

    it "leaves the values unbracketed where a cut falls inside a note" do
      source = "{ \\tuplet 3/2 4 { c'4 d' e' } c'2 }"
      expect([groups(source), events(source)[1]]).to eq [[], ["1:1:640", "triplet quarter"]]
    end
  end

  it "ends a bracket on the link where a tie leaves it" do
    source = "{ \\tuplet 3/2 { c'8 d' e'~ } e'4 f'2 }"
    expect(events(source)[2]).to eq ["1:1:640", "triplet eighth tied to quarter"]
    expect(groups(source)).to eq [["1:1:000", "1:2:000", "triplet", "eighth"]]
  end

  it "starts a bracket on the link where a tie enters it" do
    source = "{ c'4~ \\tuplet 3/2 { c'8 d' e' } f'2 }"
    expect(events(source)[0]).to eq ["1:1:000", "quarter tied to triplet eighth"]
    expect(groups(source)).to eq [["1:2:000", "1:3:000", "triplet", "eighth"]]
  end

  it "gives rests and chords the ratio" do
    source = "{ \\tuplet 3/2 { <c' e'>8 r e' } f'2. }"
    expect(events(source).first(2).map(&:last)).to eq ["triplet eighth", "triplet eighth"]
    expect(groups(source)).to eq [["1:1:000", "1:2:000", "triplet", "eighth"]]
  end

  it "scales a spacer inside it into a rest under the ratio" do
    source = "{ \\tuplet 3/2 { c'8 s e' } f'2. }"
    rest = voice(source).voice_events[1]
    expect([rest.rest?, rest.rhythmic_value.to_s, rest.position.to_s]).to eq [true, "triplet eighth", "1:1:320"]
  end

  it "scales an \\after inside it" do
    source = "{ \\tuplet 3/2 { \\after 8 \\p c'4 d'8 } f'2. }"
    expect(voice(source).dynamic_events.map(&:to_s)).to eq ["p at 1:1:320"]
  end

  it "leaves an \\after outside it unscaled" do
    source = "{ \\after 8 \\p \\tuplet 3/2 { c'4 d'8 } f'2. }"
    expect(voice(source).dynamic_events.map(&:to_s)).to eq ["p at 1:1:480"]
  end

  it "passes a bar check at the bar's end" do
    expect(groups("{ \\tuplet 3/2 { c'2 d' e' } | c'1 }")).to eq [["1:1:000", "2:1:000", "triplet", "half"]]
  end

  it "fails a bar check that falls inside the bar" do
    expect { voice("{ \\tuplet 3/2 { c'8 d' e' } | f'2. }") }
      .to raise_error(HeadMusic::Notation::LilyPond::ParseError, %r{Bar check failed at: 1/4 in bar 1})
  end

  it "names a failed bar check's place to the subtick" do
    expect { voice("{ \\tuplet 7/4 { c'16 d' | e' f' g' a' b' } c'2. }") }
      .to raise_error(HeadMusic::Notation::LilyPond::ParseError, %r{Bar check failed at: 21943/307200 in bar 1})
  end

  it "reads a ratio of one as plain music" do
    expect([events("{ \\tuplet 1/1 { c'4 } c'2. }").first, groups("{ \\tuplet 1/1 { c'4 } c'2. }")]).to eq [["1:1:000", "quarter"], []]
  end

  it "brackets each voice's tuplets in that voice" do
    source = "<< \\new Staff { \\tuplet 3/2 { c''8 d'' e'' } f''2. } \\new Staff { c4 \\tuplet 5/4 { c16 d e f g } c2 } >>"
    expect(HeadMusic::Notation::LilyPond.parse(source).voices.map { |voice| voice.tuplets.map(&:to_s) })
      .to eq [["3:2 tuplet from 1:1:000 to 1:2:000"], ["5:4 tuplet from 1:2:000 to 1:3:000"]]
  end

  {
    "{ \\tuplet 3/2 { c'8 \\tuplet 3/2 { d'16 e' f' } g'8 } }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Nested tuplets are not supported/],
    "{ \\tuplet 3/2 { R1 } }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /A whole-bar rest inside a tuplet/],
    "{ \\tuplet 3/2 { << { c'4 } \\\\ { e'4 } >> } }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Simultaneous music inside a tuplet/],
    "{ \\tuplet { c'4 } }" => [HeadMusic::Notation::LilyPond::ParseError, /\\tuplet expects a fraction/],
    "{ \\times 0/2 { c'4 } }" => [HeadMusic::Notation::LilyPond::ParseError, /\\times expects a positive fraction/],
    "{ \\tuplet 3/2 }" => [HeadMusic::Notation::LilyPond::ParseError, /\\tuplet expects music/],
    "{ \\tupletSpan c'4 }" => [HeadMusic::Notation::LilyPond::ParseError, /\\tupletSpan expects a duration or \\default/],
    "{ \\tuplet 3/2 3 { c'8 } }" => [HeadMusic::Notation::LilyPond::ParseError, /Unrecognized duration "3"/]
  }.each do |source, (error_class, message)|
    it "raises for #{source}" do
      expect { voice(source) }.to raise_error(error_class, message)
    end
  end
end
