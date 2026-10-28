module HeadMusic::MIDI
  # [time, microseconds] tempo changes in time order after an opening
  # tempo, and the runs among them, as export steps a ramp: changes all
  # faster or all slower than the one before, each a count or less after
  # the one before.
  class TempoChanges
    delegate :[], :first, :last, :length, :empty?, to: :to_a

    def initialize(layout, opening, changes = [])
      @layout = layout
      @opening = opening
      @changes = changes
    end

    def to_a
      @changes
    end

    # Adds a change unless it is to the tempo already in force.
    def <<(change)
      @changes << change unless change.last == tempo_before
      self
    end

    def with(change)
      self.class.new(@layout, @opening, [*@changes, change])
    end

    # The tempo in force before the change at +index+.
    def tempo_before(index = length)
      index.zero? ? @opening : @changes[index - 1].last
    end

    # The indexes of the run through +index+, walking to its end by +step+,
    # 1 to go later or -1 earlier.
    def run(index, step)
      direction = direction(index)
      edge = index
      edge += step while linked?(*[edge, edge + step].minmax, direction)
      Range.new(*[index, edge].minmax)
    end

    # Whether at least two of a run's changes fall within bars, as a ramp's
    # do.
    def ramp?(run)
      @changes[run].count { |time, _| !@layout.downbeat?(time) } >= 2
    end

    # The step a run of at least two changes at the end would take at +time+,
    # a count or less after its last, carried on in a straight line in beats
    # a minute, as a ramp's steps run.
    def next_step(time)
      last = length - 1
      return unless last >= 1 && run(last, -1).size >= 2 && in_step?(@changes[last], [time])

      per_minute = 2 * per_minute(@changes[last].last) - per_minute(tempo_before(last))
      per_minute(per_minute).round if per_minute.positive?
    end

    # The last index of the run from +index+, if it is a ramp's, whose last
    # change holds until the next downbeat.
    def ramp_end(index)
      finish = run(index, 1).end
      finish if ramp?(index..finish) && held?(@changes[finish].first, @changes[finish + 1])
    end

    # The tempo before the run ending at +last+, added after these, if it is
    # a ramp's.
    def ramp_start(last)
      changes = with(last)
      run = changes.run(length, -1)
      changes.tempo_before(run.begin) if changes.ramp?(run)
    end

    # Whether a ramp's run goes on through +step+, under a fermata, to
    # +restore+ and +following+ after it.
    def ramp_through?(step, restore, following)
      return false unless following

      changes = with(step).with(restore).with(following)
      changes.run(length, 1).end == changes.length - 1 && changes.run(length, -1).begin < length
    end

    # Whether +slow+ is nearer the ramp's next +step+ than halfway back to
    # its last, so a step of the ramp, not a fermata.
    def on_line?(slow, step)
      2 * (per_minute(slow) - per_minute(step)).abs <= (per_minute(step) - per_minute(tempo_before)).abs
    end

    # Whether a tempo at +time+ holds until the first downbeat at or after
    # it, or with +through+, past it, given the change +following+ it.
    def held?(time, following, through: false)
      return true if following.nil? || @layout.downbeat?(time)

      end_time = @layout.bar_at(time).end_time
      through ? following.first > end_time : following.first >= end_time
    end

    # Converts between microseconds a quarter and quarters a minute, either
    # way.
    def per_minute(value)
      Rational(60_000_000, value)
    end

    private

    # Whether +after+ is a count or less after +before+, as steps under a
    # ramp are.
    def in_step?(before, after)
      after.first - before.first <= Rational(1, @layout.bar_at(before.first).meter.bottom_number)
    end

    def linked?(before, after, direction)
      before >= 0 && after < length && [before, after].all? { |index| direction(index) == direction } && in_step?(@changes[before], @changes[after])
    end

    def direction(index)
      @changes[index].last <=> tempo_before(index)
    end
  end
end
