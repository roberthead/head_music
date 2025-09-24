module HeadMusic::Rudiment; end

# Represents a musical tempo with a beat value and beats per minute
class HeadMusic::Rudiment::Tempo
  SECONDS_PER_MINUTE = 60
  NANOSECONDS_PER_SECOND = 1_000_000_000
  NANOSECONDS_PER_MINUTE = (NANOSECONDS_PER_SECOND * SECONDS_PER_MINUTE).freeze

  attr_reader :beat_value, :beats_per_minute

  delegate :ticks, to: :beat_value, prefix: true
  alias_method :ticks_per_beat, :beat_value_ticks

  NAMED_TEMPO_DEFAULTS = {
    larghissimo: ["quarter", 24],       # 24–40 bpm
    adagissimo: ["quarter", 32],        # 24–40 bpm
    grave: ["quarter", 32],             # 24–40 bpm
    largo: ["quarter", 54],             # 40–66 bpm
    larghetto: ["quarter", 54],         # 44–66 bpm
    adagio: ["quarter", 60],            # 44–66 bpm
    adagietto: ["quarter", 68],         # 46–80 bpm
    lento: ["quarter", 72],             # 52–108 bpm
    marcia_moderato: ["quarter", 72],   # 66–80 bpm
    andante: ["quarter", 78],           # 56–108 bpm
    andante_moderato: ["quarter", 88],  # 80–108 bpm
    andantino: ["quarter", 92],         # 80–108 bpm
    moderato: ["quarter", 108],         # 108–120 bpm
    allegretto: ["quarter", 112],       # 112–120 bpm
    allegro_moderato: ["quarter", 116], # 116–120 bpm
    allegro: ["quarter", 120],          # 120–156 bpm
    molto_allegro: ["quarter", 132],    # 124–156 bpm
    allegro_vivace: ["quarter", 132],   # 124–156 bpm
    vivace: ["quarter", 156],           # 156–176 bpm
    vivacissimo: ["quarter", 172],      # 172–176 bpm
    allegrissimo: ["quarter", 172],     # 172–176 bpm
    presto: ["quarter", 180],           # 168–200 bpm
    prestissimo: ["quarter", 200]      # 200 bpm and over
  }

  def self.get(identifier)
    @tempos ||= {}
    key = HeadMusic::Utilities::HashKey.for(identifier)
    if NAMED_TEMPO_DEFAULTS.key?(identifier.to_s.to_sym)
      beat_value, beats_per_minute = NAMED_TEMPO_DEFAULTS[identifier.to_s.to_sym]
      @tempos[key] ||= new(beat_value, beats_per_minute)
    elsif identifier.to_s.match?(/=|at/)
      parts = identifier.to_s.split(/\s*(=|at)\s*/)
      unit = parts[0]
      bpm = parts[2] || parts[1]  # Handle both "q = 120" and "q at 120bpm"
      bpm_value = bpm.to_s.gsub(/[^0-9]/, "").to_i
      @tempos[key] ||= new(standardized_unit(unit), bpm_value)
    else
      @tempos[key] ||= new("quarter", 120)
    end
    @tempos[key]
  end

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

  def self.standardized_unit(unit)
    # Try to parse using the RhythmicUnit parser first
    parsed_unit = HeadMusic::Rudiment::RhythmicUnit::Parser.parse(unit)
    return parsed_unit if parsed_unit

    # Fallback to the old logic
    case unit.to_s.downcase.strip
    when "q", "1/4", "crotchet"
      "quarter"
    when "h", "1/2", "minim"
      "half"
    when "e", "1/8", "quaver"
      "eighth"
    when "s", "1/16", "semiquaver"
      "sixteenth"
    else
      "quarter"
    end
  end
end
