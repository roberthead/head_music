require "spec_helper"

describe HeadMusic::MIDI::ChunkReader do
  def header(format: 1, tracks: 1, division: 480)
    ["MThd", 6, format, tracks, division].pack("a4Nnnn")
  end

  def chunk(type, body)
    [type, body.bytesize].pack("a4N") + body
  end

  def ranges(bytes)
    ranges = []
    described_class.new(bytes).each_track { |start, limit| ranges << [start, limit] }
    ranges
  end

  it "reads the header's format, track count, and division" do
    expect(described_class.new(header(format: 0, division: 96))).to have_attributes(format: 0, track_count: 1, division: 96)
  end

  it "yields each MTrk chunk's body range, skipping unknown chunks" do
    expect(ranges(header(tracks: 2) + chunk("MTrk", "ab") + chunk("XFIH", "zz") + chunk("MTrk", "c"))).to eq [[22, 24], [42, 43]]
  end

  it "reads a complete chunk past the declared count and ignores trailing bytes" do
    expect(ranges(header + chunk("MTrk", "a") + chunk("MTrk", "b") + "junk")).to eq [[22, 23], [31, 32]]
  end

  it "reads each chunk only as the caller reaches it" do
    reached = []
    expect { described_class.new(header(tracks: 2) + chunk("MTrk", "a") + "MTr").each_track { |start, _limit| reached << start } }
      .to raise_error(HeadMusic::MIDI::ParseError, /truncated chunk header/)
    expect(reached).to eq [22]
  end

  it "raises on fewer tracks than declared" do
    expect { ranges(header(tracks: 2) + chunk("MTrk", "a")) }.to raise_error(HeadMusic::MIDI::ParseError, /expected 2 tracks, found 1/)
  end

  it "raises UnsupportedFeatureError for format 2" do
    expect { described_class.new(header(format: 2)) }.to raise_error(HeadMusic::MIDI::UnsupportedFeatureError)
  end

  it "raises UnsupportedFeatureError for an SMPTE division" do
    expect { described_class.new(header(division: 0xE728)) }.to raise_error(HeadMusic::MIDI::UnsupportedFeatureError, /SMPTE/)
  end
end
