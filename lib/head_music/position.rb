class HeadMusic::Position
  include Comparable

  attr_reader :composition, :measure_number, :count, :tick
  delegate :to_s, to: :code
  delegate :meter, to: :composition

  def initialize(composition, code_or_measure, count = nil, tick = nil)
    if code_or_measure.is_a?(String) && code_or_measure =~ /\D/
      ensure_state(composition, *code_or_measure.split(/\D+/))
    else
      ensure_state(composition, code_or_measure, count, tick)
    end
  end

  def code
    values.join(':')
  end

  def state
    [composition.name, code].join(' ')
  end

  def values
    [measure_number, count, tick]
  end

  def <=>(other)
    self.values <=> other.values
  end

  private

  def ensure_state(composition, measure_number, count, tick)
    @composition = composition
    @measure_number = measure_number.to_i
    @count = (count || 1).to_i
    @tick = (tick || 0).to_i
    roll_over_units
  end

  def roll_over_units
    roll_over_ticks
    roll_over_counts
  end

  def roll_over_ticks
    while @tick > meter.ticks_per_count
      @tick -= meter.ticks_per_count.to_i
      @count += 1
    end
  end

  def roll_over_counts
    while @count > meter.counts_per_measure
      @count -= meter.counts_per_measure
      @measure_number += 1
    end
  end
end

# In Logic Pro X, the 'beat' is determined by the denominator, even if compound.
# Logic then divides the beat into 'divisions' that are a sixteenth in length.
# Each division is then divided into 240 ticks (960 PPQN / 4 sixteenths-per-quarter)

# Tempo specifies the beat unit, usually the traditional beat unit in the case of compound meters,
# so 6/8 would specify [dotted-quarter] = 132 (or whatever).
