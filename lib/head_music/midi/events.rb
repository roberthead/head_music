# Timed MIDI events, each at an absolute tick on a 0-based wire channel.
# #payload is the event's bytes after its delta time, and #rank orders events
# that share a tick: names, then the conductor's meta events, program changes,
# releases, lyrics, attacks, and the end of the track.
module HeadMusic::MIDI
  NoteOn = Data.define(:tick, :channel, :key, :velocity) do
    def payload
      [0x90 | channel, key, velocity].pack("C3")
    end

    def rank
      5
    end
  end

  NoteOff = Data.define(:tick, :channel, :key, :velocity) do
    def initialize(tick:, channel:, key:, velocity: 64)
      super
    end

    def payload
      [0x80 | channel, key, velocity].pack("C3")
    end

    def rank
      3
    end
  end

  # +program+ is 1-based, as General MIDI tables print it; the wire is 0-based.
  ProgramChange = Data.define(:tick, :channel, :program) do
    def payload
      [0xC0 | channel, program - 1].pack("C2")
    end

    def rank
      2
    end
  end

  Tempo = Data.define(:tick, :microseconds_per_quarter) do
    # A dotted quarter at 60 is 666,667.
    def self.microseconds_per_quarter(tempo)
      (Rational(60_000_000) / (tempo.beats_per_minute.to_r * tempo.beat_value.fraction * 4)).round
    end

    def payload
      Meta.bytes(0x51, [microseconds_per_quarter].pack("N").byteslice(1, 3))
    end

    def rank
      1
    end
  end

  TimeSignature = Data.define(:tick, :numerator, :denominator, :clocks_per_click) do
    # 24 MIDI clocks to the quarter, so 6/8's dotted quarter is 36. Exact, so
    # preflight can refuse a click MIDI cannot count.
    def self.clocks_per_click(meter)
      Rational(meter.compound? ? 288 : 96, meter.bottom_number)
    end

    def payload
      Meta.bytes(0x58, [numerator, denominator.bit_length - 1, clocks_per_click, 8].pack("C4"))
    end

    def rank
      1
    end
  end

  KeySignature = Data.define(:tick, :fifths, :minor) do
    def payload
      Meta.bytes(0x59, [fifths, minor ? 1 : 0].pack("cC"))
    end

    def rank
      1
    end
  end

  Text = Data.define(:tick, :kind, :text) do
    def payload
      Meta.bytes(Meta::TEXT_TYPES.fetch(kind), text.encode("UTF-8").b)
    end

    def rank
      (kind == :lyric) ? 4 : 0
    end
  end

  EndOfTrack = Data.define(:tick) do
    def payload
      Meta.bytes(0x2F, "".b)
    end

    def rank
      6
    end
  end

  module Meta
    TEXT_TYPES = {
      text: 0x01, copyright: 0x02, sequence_name: 0x03, track_name: 0x03,
      instrument_name: 0x04, lyric: 0x05, marker: 0x06, cue_point: 0x07
    }.freeze

    def self.bytes(type, data)
      [0xFF, type].pack("C2") + SMF.vlq(data.bytesize) + data
    end
  end
end
