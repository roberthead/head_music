class HeadMusic::HarmonicInterval
  attr_reader :voice1, :voice2, :position

  def initialize(voice1, voice2, position)
    @voice1 = voice1
    @voice2 = voice2
    @position = position.is_a?(String) ? Position.new(voice1.composition, position) : position
  end

  def functional_interval
    @functional_interval ||= HeadMusic::FunctionalInterval.new(lower_pitch, upper_pitch)
  end

  def voices
    [voice1, voice2].reject(&:nil?)
  end

  def notes
    @notes ||= voices.map { |voice| voice.note_at(position) }.reject(&:nil?).sort_by(&:pitch)
  end

  def lower_note
    notes.first
  end

  def upper_note
    notes.last
  end

  def pitches
    @pitches ||= notes.map(&:pitch).sort_by(&:to_i)
  end

  def lower_pitch
    pitches.first
  end

  def upper_pitch
    pitches.last
  end

  def to_s
    "#{functional_interval} at #{position}"
  end

  def method_missing(method_name, *args, &block)
    functional_interval.send(method_name, *args, &block)
  end
end
