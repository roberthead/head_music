require "spec_helper"

describe HeadMusic::Notation::LilyPond::VoiceItemReader do
  def voice(source)
    HeadMusic::Notation::LilyPond.parse(source).voices.first
  end

  def events(source)
    voice(source).voice_events.map { |event| [event.position.to_s, event.rest? ? "r" : event.pitches.join(" ")] }
  end

  it "reads notes, rests, chords, and nested braces in order" do
    expect(events("{ c'4 r4 { <e' g'>4 } d'4 }")).to eq [
      ["1:1:000", "C4"], ["1:2:000", "r"], ["1:3:000", "E4 G4"], ["1:4:000", "D4"]
    ]
  end

  it "reads the settings and bar marks among the notes" do
    flow = HeadMusic::Notation::LilyPond.parse("{ c'1 \\time 3/4 \\bar \"||\" d'2. }")
    expect([flow.meter_at(2).to_s, flow.bars(1).last.barline]).to eq ["3/4", :double]
  end

  it "reads a wrapper command's music through the MusicReader" do
    expect(events("{ \\relative c' { c4 e g c } }").map(&:last)).to eq %w[C4 E4 G4 C5]
  end

  it "reads the one item an \\after wraps" do
    flow = HeadMusic::Notation::LilyPond.parse("{ \\after 2 \\f c'1 }")
    expect(flow.voices.first.dynamic_events.map { |event| event.position.to_s }).to eq ["1:3:000"]
  end

  it "reads the main note of an \\afterGrace and drops its grace notes" do
    expect(voice("{ \\afterGrace c'2 { d'16 } e'2 }").voice_events.map { |event| event.grace_notes.length }).to eq [0, 0]
  end

  it "refuses an \\after with no music to wrap" do
    expect { voice("{ \\after 2 \\f }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /\\after expects music/)
  end

  it "refuses an \\afterGrace with no music to wrap" do
    expect { voice("{ \\afterGrace }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /\\afterGrace expects music/)
  end

  it "refuses a whole-bar rest inside a tuplet" do
    expect { voice("{ \\tuplet 3/2 { R1 } }") }
      .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /A whole-bar rest inside a tuplet/)
  end

  it "refuses a document command inside music" do
    expect { voice("{ c'4 \\header { } }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected \\header inside music/)
  end
end
