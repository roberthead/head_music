# frozen_string_literal: true

# A position is a moment in time within the rhythmic framework of a composition.
class HeadMusic::Position
  include Comparable

  attr_reader :composition, :bar_number, :count, :tick
  delegate :to_s, to: :code

  def initialize(composition, code_or_bar, count = nil, tick = nil)
    if code_or_bar.is_a?(String) && code_or_bar =~ /\D/
      bar_number, count, tick = code_or_bar.split(/\D+/)
      ensure_state(composition, bar_number, count, tick)
    else
      ensure_state(composition, code_or_bar, count, tick)
    end
  end

  def meter
    composition.meter_at(bar_number)
  end

  def code
    tick_string = tick.to_s.rjust(3, '0')
    [bar_number, count, tick_string].join(':')
  end

  def state
    [composition.name, code].join(' ')
  end

  def values
    [bar_number, count, tick]
  end

  def within_placement?(placement)
    placement.position <= self && placement.next_position > self
  end

  def <=>(other)
    other = self.class.new(composition, other) if other.is_a?(String) && other =~ /\D/
    values <=> other.values
  end

  def strength
    meter.beat_strength(count, tick: tick)
  end

  def strong?
    strength >= 80
  end

  def weak?
    !strong?
  end

  def +(other)
    other = HeadMusic::RhythmicValue.new(other) if [HeadMusic::RhythmicUnit, Symbol, String].include?(other.class)
    self.class.new(composition, bar_number, count, tick + other.ticks)
  end

  def start_of_next_bar
    self.class.new(composition, bar_number + 1, 1, 0)
  end

  private

  def ensure_state(composition, bar_number, count, tick = nil)
    @composition = composition
    @bar_number = bar_number.to_i
    @count = (count || 1).to_i
    @tick = (tick || 0).to_i
    roll_over_units
  end

  def roll_over_units
    roll_over_ticks
    roll_over_counts
  end

  def roll_over_ticks
    while @tick >= meter.ticks_per_count
      @tick -= meter.ticks_per_count.to_i
      @count += 1
    end
  end

  def roll_over_counts
    while @count > meter.counts_per_bar
      @count -= meter.counts_per_bar
      @bar_number += 1
    end
  end
end

# In Logic Pro X, the 'beat' is determined by the denominator, even if compound.
# Logic then divides the beat into 'divisions' that are a sixteenth in length.
# Each division is then divided into 240 ticks (960 PPQN / 4 sixteenths-per-quarter)

# Tempo specifies the beat unit, usually the traditional beat unit in the case of compound meters,
# so 6/8 would specify [dotted-quarter] = 132 (or whatever).
