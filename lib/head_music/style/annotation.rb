class HeadMusic::Style::Annotation
  MESSAGE = 'Write music.'

  attr_reader :voice

  delegate(
    :composition,
    :highest_pitch,
    :lowest_pitch,
    :highest_notes,
    :lowest_notes,
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

  def initialize(voice)
    @voice = voice
  end

  def fitness
    [marks].flatten.compact.map(&:fitness).reduce(1, :*)
  end

  def perfect?
    fitness == 1
  end

  def notes?
    first_note
  end

  def start_position
    [marks].flatten.compact.map(&:start_position).sort.first
  end

  def end_position
    [marks].flatten.compact.map(&:end_position).sort.last
  end

  def marks
    raise NotImplementedError
  end

  def message
    self.class::MESSAGE
  end

  protected

  def first_note
    notes && notes.first
  end

  def last_note
    notes && notes.last
  end

  def voices
    @voices ||= voice.composition.voices
  end

  def other_voices
    @other_voices ||= voices.select { |part| part != voice }
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

  def functional_interval_from_tonic(note)
    HeadMusic::FunctionalInterval.new(tonic_spelling, note.spelling)
  end

  def bass_voice?
    lower_voices.empty?
  end

  def starts_on_tonic?
    tonic_spelling == first_note.spelling
  end

  def motions
    downbeat_harmonic_intervals.map.with_index do |harmonic_interval, i|
      next_harmonic_interval = downbeat_harmonic_intervals[i+1]
      HeadMusic::Motion.new(harmonic_interval, next_harmonic_interval) if next_harmonic_interval
    end.compact
  end

  def downbeat_harmonic_intervals
    @downbeat_harmonic_intervals ||=
      cantus_firmus.notes.map { |cantus_firmus_note|
        HeadMusic::HarmonicInterval.new(cantus_firmus_note.voice, voice, cantus_firmus_note.position)
      }.reject { |interval| interval.notes.length < 2 }
  end

  def harmonic_intervals
    @harmonic_intervals ||=
      positions.map { |position|
        HeadMusic::HarmonicInterval.new(cantus_firmus, voice, position)
      }.reject { |harmonic_interval| harmonic_interval.notes.length < 2 }
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
end
