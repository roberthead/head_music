module HeadMusic::Rudiment; end

# Represents a musical tempo with a beat value and beats per minute
class HeadMusic::Rudiment::Tempo
  SECONDS_PER_MINUTE = 60
  NANOSECONDS_PER_SECOND = 1_000_000_000
  NANOSECONDS_PER_MINUTE = (NANOSECONDS_PER_SECOND * SECONDS_PER_MINUTE).freeze

  attr_reader :beat_value, :beats_per_minute

  delegate :ticks, to: :beat_value, prefix: true
  alias_method :ticks_per_beat, :beat_value_ticks

  def initialize(beat_value, beats_per_minute)
    @beat_value = HeadMusic::Rudiment::RhythmicValue.get(beat_value)
    @beats_per_minute = beats_per_minute.to_f
  end

  def beat_duration_in_seconds
    @beat_duration_in_seconds ||=
      SECONDS_PER_MINUTE / beats_per_minute
  end

  def beat_duration_in_nanoseconds
    @beat_duration_in_nanoseconds ||=
      NANOSECONDS_PER_MINUTE / beats_per_minute
  end

  def tick_duration_in_nanoseconds
    @tick_duration_in_nanoseconds ||=
      beat_duration_in_nanoseconds / ticks_per_beat
  end
end
