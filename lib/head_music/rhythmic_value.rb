class HeadMusic::RhythmicValue
  PPQN = PULSES_PER_QUARTER_NOTE = 960

  attr_reader :unit, :dots

  delegate :name, to: :unit, prefix: true

  def initialize(unit, dots: nil)
    @unit = HeadMusic::RhythmicUnit.get(unit)
    @dots = [0, 1, 2, 3].include?(dots) ? dots : 0
  end

  def unit_value
    unit.relative_value
  end

  def relative_value
    unit_value * multiplier
  end

  def multiplier
    (0..dots).reduce(0) { |sum, i| sum += (1.0/2)**i }
  end

  def measures
    @denominator > 1 ? 0 : relative_value
  end

  def ticks
    PPQN * 4 * relative_value
  end

  def measures
    relative_value >= 1 ? relative_value : 0
  end

  def ticks
    PPQN * 4 * relative_value
  end

  def per_whole
    1.0 / relative_value
  end

  def name_modifier_prefix
    case dots
    when 1
      'dotted'
    when 2
      'double-dotted'
    when 3
      'triple-dotted'
    end
  end

  def name
    [name_modifier_prefix, unit_name].reject(&:nil?).join(' ')
  end
end
