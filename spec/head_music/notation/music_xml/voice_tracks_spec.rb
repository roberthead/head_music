require "spec_helper"

describe HeadMusic::Notation::MusicXML::VoiceTracks do
  subject(:tracks) { described_class.new(HeadMusic::Notation::MusicXML::PartStaves.new) }

  let(:durations) { HeadMusic::Notation::MusicXML::PartDurations.new(divisions: Rational(1)) }

  def note(step, extra = "", duration: 1, type: "quarter")
    xml = "<note>#{extra}<pitch><step>#{step}</step><octave>4</octave></pitch><duration>#{duration}</duration><type>#{type}</type></note>"
    HeadMusic::Notation::MusicXML::NoteReader.read(REXML::Document.new(xml).root)
  end

  def add(note)
    tracks.add(note, durations, measure_index: 0, cursor: 0, duration: Rational(1, 4), fills_bar: false)
  end

  it "adds a main note to its voice's track" do
    event = add(note("C", "<voice>2</voice>"))
    expect([tracks.to_a.map(&:label), event.sounds.map(&:to_s), event.rhythmic_duration]).to eq [
      ["2"], ["C4"], HeadMusic::Rudiment::RhythmicDuration.get(:quarter)
    ]
  end

  it "keeps a main note's ties by the pitch they sound" do
    event = add(note("C").tap { |tied| tied.ties.push("start", "stop") })
    expect([event.tie_starts, event.tie_stops]).to eq [["C4"], ["C4"]]
  end

  it "sounds a chord tone with the note before it" do
    lead = add(note("C"))
    expect(tracks.add_chord_tone(note("E", "<chord/>"), durations)).to equal lead
    expect(lead.sounds.map(&:to_s)).to eq %w[C4 E4]
  end

  it "drops a hidden note's chord tones with it" do
    add(note("C"))
    tracks.hide_lead
    expect(tracks.add_chord_tone(note("E", "<chord/>"), durations)).to be_nil
  end

  it "refuses a chord tone with no note before it" do
    expect { tracks.add_chord_tone(note("E", "<chord/>"), durations) }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /has no note before it/)
  end

  it "forgets the lead at a new measure" do
    add(note("C"))
    tracks.start_measure({measure: "2", part: "P1"})
    expect { tracks.add_chord_tone(note("E", "<chord/>"), durations) }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /\(measure 2 of part P1\)/)
  end

  it "refuses chord tones of different lengths" do
    add(note("C"))
    expect { tracks.add_chord_tone(note("E", "<chord/>", duration: 2, type: "half"), durations) }
      .to raise_error(HeadMusic::Notation::MusicXML::UnsupportedFeatureError, /different lengths/)
  end

  it "queues a grace note, an eighth where it has no type, for its voice's next main note" do
    grace, chord = tracks.add_grace(note("D", "<grace/>").tap { |untyped| untyped.type = nil })
    event = add(note("C"))
    expect([grace.rhythmic_value, chord, event.graces]).to eq [HeadMusic::Rudiment::RhythmicValue.get(:eighth), false, [grace]]
  end

  it "joins a grace chord's tones to the grace note before them" do
    grace, = tracks.add_grace(note("D", "<grace/>"))
    expect(tracks.add_grace(note("F", "<grace/><chord/>"))).to eq [grace, true]
    expect(grace.sounds.map(&:to_s)).to eq %w[D4 F4]
  end
end
