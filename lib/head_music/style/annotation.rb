class HeadMusic::Style::Annotation
  attr_reader :voice

  delegate(
    :composition,
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
    raise NotImplementedError
  end

  def first_note
    notes && notes.first
  end

  def last_note
    notes && notes.last
  end

  def other_voices
    @other_voices ||= voice.composition.voices.select { |part| part != voice }
  end

  def cantus_firmus
    other_voices.detect(&:cantus_firmus?) || other_voices.first
  end
end
