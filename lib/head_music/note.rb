class HeadMusic::Note
  attr_reader :pitch, :rhythmic_value

  delegate :ticks, to: :rhythmic_value

  def initialize(pitch, rhythmic_unit, rhythmic_value_modifiers = {})
    @pitch = HeadMusic::Pitch.get(pitch)
    @rhythmic_value = HeadMusic::RhythmicValue.new(rhythmic_unit, rhythmic_value_modifiers)
  end

  def duration
    rhythmic_value.total_value
  end
end
