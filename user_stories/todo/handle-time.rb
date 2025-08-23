# The Time module provides classes and methods to handle representations
# of musical time and its relationship to clock time and SMPTE Time Code.
module HeadMusic::Time
  # ticks per quarter note value
  PPQN = PULSES_PER_QUARTER_NOTE = 960
  SUBTICKS_PER_TICK = 240
end

class HeadMusic::Time::Value
  include Comparable

  attr_reader :nanoseconds

  def initialize(nanoseconds)
    @nanoseconds = nanoseconds
  end

  def to_i
    nanoseconds
  end

  def to_microseconds
    nanoseconds / 1_000.0
  end

  def to_milliseconds
    nanoseconds / 1_000_000.0
  end

  def to_seconds
    nanoseconds / 1_000_000_000.0
  end

  def +(other)
    HeadMusic::Time::Value.new(nanoseconds + other.to_i)
  end

  def <=>(other)
    nanoseconds <=> other.to_i
  end
end

# Representation of a musical position.
# Consists of:
# - bar
# - beat (or count)
# - tick (960 ticks / quarter note value)
# - subtick (240 subticks / tick)
#
# Note: In the absence of a specific meter,
# no math can be performed on the position.
class HeadMusic::Time::Position
  attr_reader :bar, :beat, :tick, :subtick

  DEFAULT_FIRST_BAR = 1
  FIRST_BEAT = 1
  FIRST_TICK = 0
  FIRST_SUBTICK = 0

  def self.parse(identifier)
    new(*identifier.scan(/\d+/)[0..3])
  end

  def initialize(
    bar = DEFAULT_FIRST_BAR,
    beat = FIRST_BEAT,
    tick = FIRST_TICK,
    subtick = FIRST_SUBTICK
  )
    @bar = bar.to_i
    @beat = beat.to_i
    @tick = tick.to_i
    @subtick = subtick.to_i
  end

  def to_a
    [bar, beat, tick, subtick]
  end

  def to_s
    "#{bar}:#{beat}:#{tick}:#{subtick}"
  end

  # Accept a meter and roll excessive values over to the next level
  def normalize!(meter)
    return self unless meter

    # Carry subticks into ticks
    if subtick >= HeadMusic::Time::SUBTICKS_PER_TICK || subtick.negative?
      tick_delta, @subtick = subtick.divmod(HeadMusic::Time::SUBTICKS_PER_TICK)
      @tick += tick_delta
    end

    # Carry ticks into beats
    if tick >= meter.ticks_per_count || tick.negative?
      beat_delta, @tick = tick.divmod(meter.ticks_per_count)
      @beat += beat_delta
    end

    # Carry beats into bars
    if beat >= meter.counts_per_bar || beat.negative?
      bar_delta, @beat = beat.divmod(meter.counts_per_bar)
      @bar += bar_delta
    end
    HeadMusic::Time::Position.new(@bar, @beat, @tick, @subtick)
  end
end

# Represents a SMPTE timecode position
# HH:MM:SS:FF (hours:minutes:seconds:frames)
class HeadMusic::Time::SmpteTimecode
  attr_reader :hour, :minute, :second, :frame

  def initialize(hour = 1, minute = 0, second = 0, frame = 0)
    @hour, @minute, @second, @frame = hour.to_i, minute.to_i, second.to_i, frame.to_i
  end
end

# Representation of a conductor track for musical material
# Each moment in a track corresponds to:
# - ellapsed clock time
#   - starts at 0.0 seconds
#   - the source-of-truth clock time
#   - nanosecond resolution
# - a position (in musical terms)
# - and a SMPTE timecode
class HeadMusic::Time::Conductor
  attr_accessor :starting_position, :starting_smpte_timecode, :framerate

  def initialize(attributes = {})
    attributes = attributes.symbolize_keys
    @starting_position = attributes.get(:starting_position, HeadMusic::Time::Position.new)
    @starting_smpte_timecode = attributes.get(:starting_smpte_timecode, HeadMusic::Time::SmpteTimecode.new)
  end
end

class HeadMusic::Time::MeterEvent
  attr_accessor :position, :meter

  def initialize(position, meter)
    @position = position
  end
end

class HeadMusic::Time::TempoEvent
  attr_accessor :position, :tempo

  # accepts a rhythmic value and a bpm
  def initialize(position, beat_value, beats_per_minute)
    @position = position
    @tempo = HeadMusic::Rudiment::Tempo.new(beat_value, beats_per_minute)
  end
end
