# A module for musical content
module HeadMusic::Content; end

# A position is a moment in time within the rhythmic framework of a flow.
#
# The coordinate itself is a HeadMusic::Time::MusicalPosition; this class is the
# binding to a flow that makes meter lookup possible. Time stays pure and
# flow-unaware, and there is one set of rollover rules rather than two.
#
# A position is **immutable**: it is normalized once at construction and then
# frozen, along with the value inside it. Positions are sort keys -- Voice#place
# binary-searches over them -- and a mutable sort key is a wrong-note bug that
# raises nothing.
class HeadMusic::Content::Position
  include Comparable

  attr_reader :flow

  delegate :count, :tick, :subtick, :to_a, to: :value
  delegate :to_s, to: :code

  def initialize(flow, code_or_bar, count = nil, tick = nil, subtick = nil)
    @flow = flow
    @value = self.class.value_for(code_or_bar, count, tick, subtick)
    normalize
    @value.freeze
    freeze
  end

  # @return [HeadMusic::Time::MusicalPosition] the coordinate, unbound
  def self.value_for(code_or_bar, count, tick, subtick)
    if code_or_bar.is_a?(String) && code_or_bar =~ /\D/
      HeadMusic::Time::MusicalPosition.parse(code_or_bar)
    else
      HeadMusic::Time::MusicalPosition.new(code_or_bar.to_i, (count || 1).to_i, (tick || 0).to_i, (subtick || 0).to_i)
    end
  end

  def bar_number
    value.bar
  end

  def meter
    flow.meter_at(bar_number)
  end

  # Subticks are emitted only when there are any, so the everyday
  # "bar:count:tick" form is unchanged and stays parseable.
  def code
    base = [bar_number, count, tick.to_s.rjust(3, "0")].join(":")
    subtick.zero? ? base : "#{base}:#{subtick.to_s.rjust(3, "0")}"
  end

  def within_placement?(placement)
    placement.position <= self && placement.next_position > self
  end

  # The flow deliberately takes no part in comparison. Positions in different
  # flows have always compared equal here, and Voice#placement_at guards with
  # exactly that comparison -- narrowing it would silently change note lookup.
  def <=>(other)
    other = self.class.new(flow, other) if other.is_a?(String) && other =~ /\D/
    to_a <=> other.to_a
  end

  def eql?(other)
    other.is_a?(self.class) && to_a == other.to_a
  end

  def hash
    to_a.hash
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
    other = HeadMusic::Rudiment::RhythmicValue.new(other) if [HeadMusic::Rudiment::RhythmicUnit, Symbol, String].include?(other.class)
    self.class.new(flow, bar_number, count, tick + other.ticks, subtick)
  end

  def start_of_next_bar
    self.class.new(flow, bar_number + 1, 1, 0)
  end

  private

  attr_reader :value

  # Normalizing a flow-bound position is not one carry but two jobs, because
  # the bars it crosses need not share a meter.
  #
  # MusicalPosition#normalize! does the radix carry -- subticks into ticks,
  # ticks into counts -- under a single meter, which is right, because those
  # ratios are read from the bar the position starts in. But its counts-into-
  # bars step is a single divmod, and that silently assumes every bar it
  # crosses has the same number of counts. So the bar carry is walked here one
  # bar at a time, asking the flow for each bar's meter as it goes.
  #
  # And the radix carry was done under the *origin* bar's meter, so a position
  # that lands in a bar with a different count unit is carried again under
  # that bar's, until it lands in a bar it was carried under. One instant then
  # has one spelling, which is what equality and hashing depend on.
  def normalize
    loop do
      origin_bar = value.bar
      counts, tick, subtick = carried_counts
      bar = origin_bar
      while counts > flow.meter_at(bar).counts_per_bar
        counts -= flow.meter_at(bar).counts_per_bar
        bar += 1
      end
      @value = HeadMusic::Time::MusicalPosition.new(bar, counts, tick, subtick)
      break if bar == origin_bar
    end
  end

  # The count the subticks and ticks carry up to, which may be more than a bar
  # holds. Any bars normalize! carried into are folded back into the count, so
  # that the walk above -- not the divmod -- decides which bar this lands in.
  def carried_counts
    carried = HeadMusic::Time::MusicalPosition.new(1, value.count, value.tick, value.subtick).normalize!(meter)
    [(carried.bar - 1) * meter.counts_per_bar + carried.count, carried.tick, carried.subtick]
  end
end

# In Logic Pro X, the 'beat' is determined by the denominator, even if compound.
# Logic then divides the beat into 'divisions' that are a sixteenth in length.
# Each division is then divided into 240 ticks (960 PPQN / 4 sixteenths-per-quarter = 240 ticks per sixteenth note)

# Tempo specifies the beat unit, usually the traditional beat unit in the case of compound meters,
# so 6/8 would specify [dotted-quarter] = 132 (or whatever).
