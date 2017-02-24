class HeadMusic::RhythmicValue
  PPQN = PULSES_PER_QUARTER_NOTE = 960

  attr_reader :unit, :dots, :tied_value

  delegate :name, to: :unit, prefix: true

  def initialize(unit, dots: nil, tied_value: nil)
    @unit = HeadMusic::RhythmicUnit.get(unit)
    @dots = [0, 1, 2, 3].include?(dots) ? dots : 0
    @tied_value = tied_value
  end

  def unit_value
    unit.relative_value
  end

  def relative_value
    unit_value * multiplier
  end

  def total_value
    relative_value + (tied_value ? tied_value.total_value : 0)
  end

  def multiplier
    (0..dots).reduce(0) { |sum, i| sum += (1.0/2)**i }
  end

  def ticks
    PPQN * 4 * total_value
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

  def single_value_name
    [name_modifier_prefix, unit_name].reject(&:nil?).join(' ')
  end

  def name
    if tied_value
      [single_value_name, tied_value.name].reject(&:nil?).join(' tied to ')
    else
      single_value_name
    end
  end
end
