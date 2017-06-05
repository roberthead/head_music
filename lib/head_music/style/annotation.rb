class HeadMusic::Style::Annotation
  MESSAGE = 'Write music.'

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
    self.class::MESSAGE
  end

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
    @cantus_firmus ||= voices.detect(&:cantus_firmus?) || other_voices.first
  end

  def higher_voices
    @higher_voices ||= voices.select { |part| part.highest_pitch > voice.highest_pitch }.sort_by(&:highest_pitch).reverse
  end

  def lower_voices
    @lower_voices ||= voices.select { |part| part.lowest_pitch < voice.lowest_pitch }.sort_by(&:lowest_pitch).reverse
  end

  def functional_interval_from_tonic(note)
    HeadMusic::FunctionalInterval.new(tonic_spelling, note.spelling)
  end

  def consonance_style
    voices.length <= 2 ? :two_part_harmony : :common_practice
  end
end
