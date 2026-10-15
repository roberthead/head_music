require "spec_helper"

describe HeadMusic::MIDI::SMF do
  describe ".vlq" do
    {
      0 => [0x00],
      0x7F => [0x7F],
      0x80 => [0x81, 0x00],
      0x3FFF => [0xFF, 0x7F],
      0x4000 => [0x81, 0x80, 0x00],
      0x1FFFFF => [0xFF, 0xFF, 0x7F],
      0x200000 => [0x81, 0x80, 0x80, 0x00],
      0x0FFFFFFF => [0xFF, 0xFF, 0xFF, 0x7F]
    }.each do |number, bytes|
      it "writes #{format("0x%X", number)} as #{bytes.map { |byte| format("%02X", byte) }.join(" ")}" do
        expect(described_class.vlq(number).bytes).to eq bytes
      end
    end

    it "refuses a negative number" do
      expect { described_class.vlq(-1) }.to raise_error(ArgumentError, /variable-length/)
    end

    it "refuses a number above 0x0FFFFFFF" do
      expect { described_class.vlq(0x10000000) }.to raise_error(ArgumentError, /variable-length/)
    end
  end

  describe ".file" do
    subject(:bytes) { described_class.file(division: 480, tracks: [[HeadMusic::MIDI::EndOfTrack.new(0)]]) }

    it "writes a format 1 header with the track count and division" do
      expect(bytes.byteslice(0, 14).bytes).to eq [*"MThd".bytes, 0, 0, 0, 6, 0, 1, 0, 1, 0x01, 0xE0]
    end

    it "writes an empty track as its end-of-track, four bytes long" do
      expect(bytes.byteslice(14..).bytes).to eq [*"MTrk".bytes, 0, 0, 0, 4, 0x00, 0xFF, 0x2F, 0x00]
    end

    it "answers a binary string" do
      expect(bytes.encoding).to eq Encoding::BINARY
    end

    it "refuses a division beyond 15 bits" do
      expect { described_class.file(division: 0x8000, tracks: []) }.to raise_error(ArgumentError, /division/)
    end

    it "takes each track's length from its bytes, counting multibyte text by bytes" do
      track = [HeadMusic::MIDI::Text.new(0, :lyric, "Café"), HeadMusic::MIDI::EndOfTrack.new(0)]
      body = described_class.file(division: 480, tracks: [track]).byteslice(14..)
      expect(body.byteslice(4, 4).unpack1("N")).to eq body.bytesize - 8
    end
  end

  describe ".track_body" do
    let(:events) do
      [
        HeadMusic::MIDI::EndOfTrack.new(480),
        HeadMusic::MIDI::NoteOn.new(0, 0, 62, 80),
        HeadMusic::MIDI::NoteOff.new(tick: 0, channel: 0, key: 60),
        HeadMusic::MIDI::Text.new(0, :lyric, "la"),
        HeadMusic::MIDI::ProgramChange.new(0, 0, 41),
        HeadMusic::MIDI::Tempo.new(0, 500_000),
        HeadMusic::MIDI::Text.new(0, :track_name, "Violin"),
        HeadMusic::MIDI::NoteOn.new(0, 0, 60, 80),
        HeadMusic::MIDI::NoteOff.new(tick: 480, channel: 0, key: 62)
      ]
    end

    def decoded
      bytes = described_class.file(division: 480, tracks: [events])
      HeadMusic::MIDI::Reader.new(bytes).read.tracks.first.events
    end

    it "orders a tick's events: names, meta, program, releases, lyrics, then attacks" do
      expect(decoded.map(&:class).first(7)).to eq [
        HeadMusic::MIDI::Text, HeadMusic::MIDI::Tempo, HeadMusic::MIDI::ProgramChange,
        HeadMusic::MIDI::NoteOff, HeadMusic::MIDI::Text, HeadMusic::MIDI::NoteOn, HeadMusic::MIDI::NoteOn
      ]
    end

    it "keeps events of one rank in the order given" do
      expect(decoded.grep(HeadMusic::MIDI::NoteOn).map(&:key)).to eq [62, 60]
    end

    it "ends with the end-of-track after a release at the same tick" do
      expect(decoded.last(2).map(&:class)).to eq [HeadMusic::MIDI::NoteOff, HeadMusic::MIDI::EndOfTrack]
    end

    it "writes deltas, not absolute ticks" do
      bytes = described_class.track_body([HeadMusic::MIDI::EndOfTrack.new(200), HeadMusic::MIDI::Tempo.new(100, 500_000)])
      expect(bytes.bytes).to eq [100, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20, 100, 0xFF, 0x2F, 0x00]
    end
  end
end
