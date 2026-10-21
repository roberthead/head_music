module HeadMusic::Rudiment; end

# Represents a musical tempo with a beat value and beats per minute, and the
# words it was written with, if any. A tempo written only in words still has a
# number, so time can be kept, and records that the number was not written.
class HeadMusic::Rudiment::Tempo
  include HeadMusic::ValueEquality

  SECONDS_PER_MINUTE = 60
  NANOSECONDS_PER_SECOND = 1_000_000_000
  NANOSECONDS_PER_MINUTE = (NANOSECONDS_PER_SECOND * SECONDS_PER_MINUTE).freeze
  DEFAULT_BEAT_VALUE = "quarter"
  DEFAULT_BEATS_PER_MINUTE = 120

  attr_reader :beat_value, :beats_per_minute, :text, :metronome_mark
  alias_method :metronome_mark?, :metronome_mark

  value_equality :beat_value, :beats_per_minute, :text, :metronome_mark

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
  }.freeze

  # Memoized on the exact identifier, since a named tempo keeps its spelling.
  def self.get(identifier)
    @tempos ||= {}
    key = identifier.to_s
    @tempos[key] ||= from_identifier(key)
  end

  # For tempo text as a score writes it: the defaults of the longest named
  # tempo the text contains as whole words, so "Allegro ma non troppo" is an
  # allegro, or else a quarter at 120.
  def self.for_text(text)
    text = text.to_s.strip
    raise ArgumentError, "tempo text must not be blank" if text.empty?

    name = NAMED_TEMPO_DEFAULTS.keys.map { |key| key.to_s.tr("_", " ") }
      .select { |phrase| text.match?(/(?<![[:alnum:]])#{Regexp.escape(phrase)}(?![[:alnum:]])/i) }
      .max_by(&:length)
    beat_value, beats_per_minute = name ? NAMED_TEMPO_DEFAULTS[name.tr(" ", "_").to_sym] : [DEFAULT_BEAT_VALUE, DEFAULT_BEATS_PER_MINUTE]
    new(beat_value, beats_per_minute, text: text, metronome_mark: false)
  end

  def self.from_identifier(identifier)
    named = NAMED_TEMPO_DEFAULTS[identifier.strip.downcase.tr(" ", "_").to_sym]
    if named
      new(*named, text: identifier.tr("_", " "), metronome_mark: false)
    elsif identifier.match?(/=|at/)
      parts = identifier.split(/\s*(=|at)\s*/)
      unit = parts[0]
      bpm = parts[2] || parts[1]  # Handle both "q = 120" and "q at 120bpm"
      bpm_value = bpm.to_s.gsub(/[^0-9]/, "").to_i
      new(standardized_unit(unit), bpm_value)
    else
      new(DEFAULT_BEAT_VALUE, DEFAULT_BEATS_PER_MINUTE)
    end
  end
  private_class_method :from_identifier

  def initialize(beat_value, beats_per_minute, text: nil, metronome_mark: true)
    @beat_value = HeadMusic::Rudiment::RhythmicValue.get(beat_value)
    @beats_per_minute = beats_per_minute.to_f
    @text = text
    @metronome_mark = metronome_mark
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
    return "quarter" if unit.nil?

    # Use RhythmicValue parser to handle all formats (shorthand, fractions, British names, dots, etc.)
    rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(unit)
    rhythmic_value&.unit ? rhythmic_value.to_s : "quarter"
  end
end
