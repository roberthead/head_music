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
end
