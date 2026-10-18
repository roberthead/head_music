require "spec_helper"

describe HeadMusic::Notation::LilyPond::GraceReader do
  def voice(source)
    HeadMusic::Notation::LilyPond.parse(source).voices.first
  end

  def graces(source)
    voice(source).voice_events.map do |event|
      event.grace_notes.map { |grace| [grace.sounds.map(&:to_s), grace.rhythmic_value.to_s, grace.slashed?, grace.tied?] }
    end
  end

  def spans(source)
    voice(source).spans.map { |span| [span.from.to_s, span.to.to_s, span.from_grace?] }
  end

  describe "the grace commands" do
    let(:source) { "{ \\grace d'16 c'4 \\slashedGrace e'8 c'4 \\appoggiatura d'8 c'4 \\acciaccatura e'8 c'4 }" }

    it "read slashed and unslashed grace notes before the main note" do
      expect(graces(source)).to eq [
        [[["D4"], "sixteenth", false, false]], [[["E4"], "eighth", true, false]],
        [[["D4"], "eighth", false, false]], [[["E4"], "eighth", true, false]]
      ]
    end

    it "slur an appoggiatura and an acciaccatura to the main note" do
      expect(spans(source)).to eq [["1:3:000", "1:3:000", true], ["1:4:000", "1:4:000", true]]
    end
  end

  it "takes no time" do
    expect(voice("{ \\grace { d'16 e' } c'4 d'2. }").voice_events.map { |event| event.position.to_s }).to eq ["1:1:000", "1:2:000"]
  end

  it "reads a braced run and a chord" do
    expect(graces("{ \\grace { d'16 <e' g'>16 } c'1 }")).to eq [[[["D4"], "sixteenth", false, false], [["E4", "G4"], "sixteenth", false, false]]]
  end

  it "starts a slur opened on the first grace note there" do
    expect(spans("{ \\grace { d'16( e' } c'4 d'4) e'2 }")).to eq [["1:1:000", "1:2:000", true]]
  end

  it "replaces the implied slur with one the first grace note opens" do
    expect(spans("{ \\acciaccatura { d'16( e' } c'4 d'4) e'2 }")).to eq [["1:1:000", "1:2:000", true]]
  end

  it "keeps the implied slur apart from a slur already open" do
    expect(spans("{ c'4( \\acciaccatura e'8 d'4) e'2 }").sort).to eq [["1:1:000", "1:2:000", false], ["1:2:000", "1:2:000", true]]
  end

  it "ends a slur that ends on a grace note on its main note" do
    expect(spans("{ c'4( \\grace d'16) e'4 f'2 }")).to eq [["1:1:000", "1:2:000", false]]
  end

  it "keeps a tie into the same pitch and drops one into another" do
    expect(graces("{ \\grace c'16~ c'4 \\grace d'16~ e'2. }").map { |notes| notes.map(&:last) }).to eq [[true], [false]]
  end

  it "keeps a grace note's articulations" do
    articulations = voice("{ \\grace d'16-. c'1 }").voice_events.first.grace_notes.first.articulations
    expect(articulations.map(&:name_key)).to eq ["staccato"]
  end

  it "drops a grace note's ornaments and accents" do
    grace = voice("{ \\grace d'16\\trill\\sfz c'1 }").voice_events.first.then { |event| [event.grace_notes.first, event] }
    expect([grace.first.articulations, grace.last.ornaments, grace.last.note_dynamic]).to eq [[], [], nil]
  end

  it "places a grace note's level at its main note" do
    expect(voice("{ c'4 \\grace d'16\\p c'2. }").dynamic_events.map(&:to_s)).to eq ["p at 1:2:000"]
  end

  it "gives a grace note's hairpin to its main note" do
    expect(voice("{ \\grace d'16\\< c'2 d'2\\! }").spans.map(&:to_s)).to eq ["crescendo from 1:1:000 to 1:3:000"]
  end

  it "carries the grace duration on" do
    expect(voice("{ c'4 \\grace d'16 c' d'8. e'2 }").voice_events[1].rhythmic_value.to_s).to eq "sixteenth"
  end

  it "reads grace pitches into \\relative" do
    expect(voice("\\relative { c''4 \\grace d16 c b2. }").voice_events.map { |event| event.pitch.to_s }).to eq %w[C5 C5 B4]
  end

  it "keeps a grace note on a note inside a tuplet, without the ratio" do
    grace = voice("{ \\tuplet 3/2 { \\grace d'16 c'8 d' e' } f'2. }").voice_events.first.grace_notes.first
    expect(grace.rhythmic_value.to_s).to eq "sixteenth"
  end

  it "waits past a bar check and a tuplet's start for its main note" do
    expect(graces("{ c'1 \\grace d'16 | \\tuplet 3/2 { c'4 d' e' } c'2 }")[1]).to eq [[["D4"], "sixteenth", false, false]]
  end

  it "joins grace commands written one after another" do
    expect(graces("{ \\grace d'16 \\slashedGrace e'16 c'1 }").first.map { |grace| grace[2] }).to eq [false, true]
  end

  {
    "before a rest" => "{ \\grace d'16 r4 c'2. }",
    "before a spacer" => "{ \\grace d'16 s4 c'2. }",
    "before a tie's later link" => "{ c'2~ \\grace d'16 c'2 }",
    "at the end of the voice" => "{ c'1 \\grace d'16 }",
    "after an \\afterGrace note" => "{ \\afterGrace c'1 { d'16 e' } }",
    "after an \\afterGrace note with a fraction" => "{ \\afterGrace 7/8 c'1 { d'16 e' } }",
    "made only of rests" => "{ \\grace { r16 } c'1 }"
  }.each do |name, source|
    it "drops grace notes #{name}" do
      expect(graces(source).flatten).to be_empty
    end
  end

  it "reads an \\afterGrace's main note" do
    expect(voice("{ \\afterGrace c'2( { d'16 e' } d'2) }").spans.map(&:to_s)).to eq ["slur from 1:1:000 to 1:3:000"]
  end

  {
    "{ \\grace { \\tuplet 3/2 { c'16 d' e' } } c'4 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Tuplets inside grace music/],
    "{ \\grace <>16 c'4 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /A <> inside grace music/],
    "{ \\grace { \\clef bass c16 } c4 }" => [HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /"\\clef"/],
    "{ \\grace }" => [HeadMusic::Notation::LilyPond::ParseError, /\\grace expects music/],
    "{ \\grace { ~ } c'4 }" => [HeadMusic::Notation::LilyPond::ParseError, /Unexpected token "~" inside grace music/],
    "{ \\afterGrace { d'16 } }" => [HeadMusic::Notation::LilyPond::ParseError, /\\afterGrace expects music/]
  }.each do |source, (error_class, message)|
    it "raises for #{source}" do
      expect { voice(source) }.to raise_error(error_class, message)
    end
  end

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
