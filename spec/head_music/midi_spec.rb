require "spec_helper"

describe HeadMusic::MIDI do
  def bytes(event)
    event.payload.bytes
  end

  it "writes a note on with its channel nibble" do
    expect(bytes(described_class::NoteOn.new(0, 2, 60, 80))).to eq [0x92, 60, 80]
  end

  it "writes a note off at velocity 64 by default" do
    expect(bytes(described_class::NoteOff.new(tick: 0, channel: 9, key: 38))).to eq [0x89, 38, 64]
  end

  it "strikes Hi Wood Block for an unpitched sound with no GM percussion key" do
    expect(described_class::DEFAULT_PERCUSSION_KEY).to eq 76
  end

  it "writes a 1-based program 0-based on the wire" do
    expect(bytes(described_class::ProgramChange.new(0, 0, 41))).to eq [0xC0, 40]
  end

  it "writes a tempo in three bytes" do
    expect(bytes(described_class::Tempo.new(0, 666_667))).to eq [0xFF, 0x51, 0x03, 0x0A, 0x2C, 0x2B]
  end

  it "writes 6/8 with 36 clocks per click and 8 thirty-seconds per quarter" do
    expect(bytes(described_class::TimeSignature.new(0, 6, 8, 36))).to eq [0xFF, 0x58, 0x04, 0x06, 0x03, 0x24, 0x08]
  end

  it "writes three flats as a signed byte" do
    expect(bytes(described_class::KeySignature.new(0, -3, false))).to eq [0xFF, 0x59, 0x02, 0xFD, 0x00]
  end

  it "writes a minor key" do
    expect(bytes(described_class::KeySignature.new(0, 1, true))).to eq [0xFF, 0x59, 0x02, 0x01, 0x01]
  end

  it "writes a lyric as UTF-8 with its byte length" do
    expect(bytes(described_class::Text.new(0, :lyric, "Café"))).to eq [0xFF, 0x05, 0x05, *"Café".bytes]
  end

  it "writes sequence and track names as meta type 3" do
    expect(bytes(described_class::Text.new(0, :track_name, "Oboe")).first(2)).to eq [0xFF, 0x03]
  end

  it "writes an end of track" do
    expect(bytes(described_class::EndOfTrack.new(0))).to eq [0xFF, 0x2F, 0x00]
  end

  it "answers binary payloads" do
    expect(described_class::Text.new(0, :lyric, "Привет").payload.encoding).to eq Encoding::BINARY
  end

  it "raises render errors that the notation writers' rescue catches" do
    expect(described_class::RenderError.ancestors).to include HeadMusic::Notation::RenderError
  end

  it "names the byte offset of a parse error" do
    expect(described_class::ParseError.new("bad", offset: 12)).to have_attributes(message: "bad (byte 12)", offset: 12)
  end
end
