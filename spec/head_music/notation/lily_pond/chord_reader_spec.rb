require "spec_helper"

describe HeadMusic::Notation::LilyPond::ChordReader do
  def chords(source)
    HeadMusic::Notation::LilyPond.parse(source).voices.first.voice_events.map { |event| [event.pitches.join(" "), event.rhythmic_duration.to_s] }
  end

  it "reads the notes inside and the value on the closer" do
    expect(chords("{ <c' e' g'>2 <d' f'>2 }")).to eq [["C4 E4 G4", "half"], ["D4 F4", "half"]]
  end

  it "carries the closer's value on to what follows" do
    expect(chords("{ <c' e'>8 <d' f'> }").map(&:last)).to eq %w[eighth eighth]
  end

  it "reads \\relative pitches from the note before inside the chord" do
    expect(chords("\\relative c' { <c e g c>1 }").first.first).to eq "C4 E4 G4 C5"
  end

  it "refuses a duration on a note inside" do
    expect { chords("{ <c'4 e'>2 }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Chord notes cannot carry durations/)
  end

  it "refuses a token that is not a note" do
    expect { chords("{ <c' r>2 }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Unexpected token "r" inside a chord/)
  end

  it "refuses a multiplier on the closer" do
    expect { chords("{ <c' e'>2*2 }") }
      .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Duration multipliers/)
  end
end
