# An Annotation encapsulates an issue with or comment on a voice
class HeadMusic::Style::Annotation
  MESSAGE = "Write music."

  DEFAULT_WEIGHT = 1.0

  attr_reader :voice

  delegate(
    :composition,
    :highest_pitch,
    :lowest_pitch,
    :highest_notes,
    :lowest_notes,
    :melodic_note_pairs,
    :melodic_intervals,
    :notes,
    :notes_not_in_key,
    :placements,
    :range,
    :rests,
    to: :voice
  )

  delegate :key_signature, to: :composition
  delegate :tonic_spelling, to: :key_signature

  def initialize(voice, **options)
    @voice = voice
    @options = options
  end

  # Wraps a guideline class with preset options so it can live in a RULESET
  # and still be instantiated with just a voice, e.g. MinimumNotes.with(minimum: 5).
  def self.with(**options)
    Configured.new(self, options)
  end

  def self.default_weight
    DEFAULT_WEIGHT
  end

  def self.default_gate?
    false
  end

  # A RULESET entry pairing a guideline class with configuration. Quacks like a
  # class to the analyze loop by responding to #new(voice).
  class Configured
    attr_reader :guideline_class, :options

    def initialize(guideline_class, options)
      @guideline_class = guideline_class
      @options = options
    end

    def new(voice)
      guideline_class.new(voice, **options)
    end

    # Layers additional options onto an already-configured entry, e.g.
    # MinimumNotes.with(5).with(gate: true), without dropping prior options.
    def with(**more)
      Configured.new(guideline_class, options.merge(more))
    end

    # Mirrors the class-level predicate so build-time RULESET filters can
    # classify any entry (bare class or configured) uniformly. A per-entry
    # gate: option takes precedence over the guideline class's default.
    def default_gate?
      options.fetch(:gate, guideline_class.default_gate?)
    end

    def name
      guideline_class.name
    end
    alias_method :to_s, :name
    alias_method :inspect, :name
  end

  def fitness
    mark_fitnesses = [marks].flatten.compact.map(&:fitness)
    return 1.0 if mark_fitnesses.empty?

    mark_fitnesses.reduce(1, :*)**(1.0 / [fitness_denominator, 1].max)
  end

  def adherent?
    fitness == 1
  end

  def weight
    options.fetch(:weight, self.class.default_weight)
  end

  def gate?
    options.fetch(:gate, self.class.default_gate?)
  end

  def has_notes?
    !!first_note
  end

  def start_position
    [marks].flatten.compact.map(&:start_position).min
  end

  def end_position
    [marks].flatten.compact.map(&:end_position).max
  end

  def message
    self.class::MESSAGE
  end

  def first_note
    notes.first
  end

  def last_note
    notes.last
  end

  protected

  attr_reader :options

  # Normalization rate for the product of mark fitnesses. Subclasses override
  # (e.g. with an opportunity count) to score by violation rate rather than
  # raw violation count. The default of 1 preserves the raw product.
  def fitness_denominator
    1
  end

  def voices
    @voices ||= voice.composition.voices
  end

  def other_voices
    @other_voices ||= voices.reject { |part| part == voice }
  end

  def cantus_firmus
    @cantus_firmus ||= other_voices.detect(&:cantus_firmus?) || other_voices.first
  end

  def higher_voices
    @higher_voices ||= unsorted_higher_voices.sort_by(&:highest_pitch).reverse
  end

  def lower_voices
    @lower_voices ||= unsorted_lower_voices.sort_by(&:lowest_pitch).reverse
  end

  def diatonic_interval_from_tonic(note)
    tonic_to_use = tonic_pitch
    tonic_to_use -= HeadMusic::Rudiment::ChromaticInterval.get(:perfect_octave) while tonic_to_use > note.pitch
    HeadMusic::Analysis::DiatonicInterval.new(tonic_to_use, note.pitch)
  end

  def bass_voice?
    lower_voices.empty?
  end

  def starts_on_tonic?
    tonic_spelling == first_note.spelling
  end

  def motions
    downbeat_harmonic_intervals.each_cons(2).map do |harmonic_interval_pair|
      HeadMusic::Analysis::Motion.new(*harmonic_interval_pair)
    end
  end

  def downbeat_harmonic_intervals
    @downbeat_harmonic_intervals ||=
      cantus_firmus.notes
        .map { |note| HeadMusic::Analysis::HarmonicInterval.new(note.voice, voice, note.position) }
        .reject { |interval| interval.notes.length < 2 }
  end

  def harmonic_intervals
    @harmonic_intervals ||=
      positions
        .map { |position| HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, position) }
        .reject { |harmonic_interval| harmonic_interval.notes.length < 2 }
  end

  def positions
    @positions ||=
      voices.map(&:notes).flatten.map(&:position).sort.uniq(&:to_s)
  end

  def unsorted_higher_voices
    other_voices.select { |part| part.highest_pitch && highest_pitch && part.highest_pitch > highest_pitch }
  end

  def unsorted_lower_voices
    other_voices.select { |part| part.lowest_pitch && lowest_pitch && part.lowest_pitch < lowest_pitch }
  end

  def tonic_pitch
    @tonic_pitch ||= HeadMusic::Rudiment::Pitch.get(tonic_spelling)
  end
end
