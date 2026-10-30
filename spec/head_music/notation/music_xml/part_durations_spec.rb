require "spec_helper"

describe HeadMusic::Notation::MusicXML::PartDurations do
  subject(:durations) { described_class.new(divisions: Rational(4)) }

  def note(xml)
    HeadMusic::Notation::MusicXML::NoteReader.read(REXML::Document.new(xml).root)
  end

  let(:quarter) { note("<note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration><type>quarter</type></note>") }
  let(:untyped_rest) { note("<note><rest/><duration>17</duration></note>") }

  it "reads a <duration> as a fraction of a whole note" do
    expect(durations.of("6")).to eq Rational(3, 8)
  end

  it "lets a <backup> or <forward> move nothing" do
    expect(durations.of("0", moving: true)).to eq 0
  end

  it "refuses a note of no duration, naming where" do
    expect { durations.of("0", measure: "2", part: "P1") }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /must be positive \(measure 2 of part P1\)/)
  end

  it "refuses a <duration> with no <divisions> in force" do
    expect { described_class.new.of("4") }.to raise_error(HeadMusic::Notation::MusicXML::ParseError, /no <divisions> in force/)
  end

  it "tolerates one division of rounding, or none before any divisions" do
    expect([durations.tolerance, described_class.new.tolerance]).to eq [Rational(1, 16), 0]
  end

  it "measures the bar by the meter in force" do
    expect(durations.with(meter: HeadMusic::Rudiment::Meter.get("3/4")).bar_length).to eq Rational(3, 4)
  end

  it "calls a measure overfull only a whole division past its bar" do
    expect([durations.overfull?(Rational(17, 16)), durations.overfull?(Rational(33, 32)), durations.overfull?(nil)])
      .to eq [true, false, nil]
  end

  it "takes an untyped rest a division over the bar for a measure rest, as music21 writes" do
    expect([durations.measure_rest?(untyped_rest, Rational(17, 16)), durations.whole_bar_rest?(untyped_rest, Rational(17, 16))])
      .to eq [true, false]
  end

  it "checks a written value against its duration" do
    expect(durations.rhythmic_duration(quarter, Rational(1, 4))).to eq HeadMusic::Rudiment::RhythmicDuration.get(:quarter)
  end

  it "refuses a written value its duration disagrees with" do
    expect { durations.rhythmic_duration(quarter, Rational(1, 2)) }
      .to raise_error(HeadMusic::Notation::MusicXML::ParseError, /A <duration> of 4 disagrees with its quarter/)
  end

  it "takes an untyped note's value from its duration" do
    expect(durations.rhythmic_duration(note("<note><rest/><duration>6</duration></note>"), Rational(3, 8)))
      .to eq HeadMusic::Rudiment::RhythmicDuration.get("dotted quarter")
  end
end
