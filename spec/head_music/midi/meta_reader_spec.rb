require "spec_helper"

describe HeadMusic::MIDI::MetaReader do
  subject(:reader) { described_class.new(480, 12) }

  def event(type, *data)
    reader.event(type, data.pack("C*"))
  end

  it "reads a tempo" do
    expect(event(0x51, 0x07, 0xA1, 0x20)).to eq HeadMusic::MIDI::Tempo.new(480, 500_000)
  end

  it "reads a time signature" do
    expect(event(0x58, 6, 3, 36, 8)).to eq HeadMusic::MIDI::TimeSignature.new(480, 6, 8, 36)
  end

  it "reads a key signature" do
    expect(event(0x59, 0xFE, 1)).to eq HeadMusic::MIDI::KeySignature.new(480, -2, true)
  end

  it "reads an end of track" do
    expect(event(0x2F)).to eq HeadMusic::MIDI::EndOfTrack.new(480)
  end

  it "reads a track name, the type a sequence name shares" do
    expect(reader.event(0x03, "Air".b)).to eq HeadMusic::MIDI::Text.new(480, :track_name, "Air")
  end

  it "reads text that is not UTF-8 as Windows-1252" do
    expect(reader.event(0x05, "Caf\xE9".b).text).to eq "Café"
  end

  it "reads only the prefix of longer data" do
    expect(event(0x51, 0x07, 0xA1, 0x20, 0xFF).microseconds_per_quarter).to eq 500_000
  end

  it "skips a type a flow cannot hold" do
    expect(event(0x7F, 0x00)).to be_nil
  end

  it "raises at its offset on data shorter than its type needs" do
    expect { event(0x59, 0) }.to raise_error(HeadMusic::MIDI::ParseError, "meta event 0x59 needs 2 bytes, not 1 (byte 12)")
  end

  it "raises UnsupportedFeatureError on a denominator above 64" do
    expect { event(0x58, 4, 7, 24, 8) }.to raise_error(HeadMusic::MIDI::UnsupportedFeatureError)
  end
end
