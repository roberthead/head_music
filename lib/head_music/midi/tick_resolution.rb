module HeadMusic::MIDI
  # Ticks per quarter note: the least common multiple of 480 and the
  # denominator of every time the file writes, so each lands on a tick. Past
  # what a division can hold, 960, with each time rounded to the nearest tick.
  class TickResolution
    BASE = 480
    FALLBACK = 960
    MAXIMUM = 0x7FFF

    attr_reader :division

    # +times+ are Rational whole notes.
    def initialize(times)
      exact = exact_division(times)
      @exact = !exact.nil?
      @division = exact || FALLBACK
    end

    def exact?
      @exact
    end

    def ticks(time)
      (time * 4 * division).round
    end

    # A note keeps at least one tick, however its ends round.
    def note_ticks(onset, release)
      on = ticks(onset)
      [on, [ticks(release), on + 1].max]
    end

    private

    def exact_division(times)
      times.reduce(BASE) do |division, time|
        division = division.lcm((Rational(time) * 4).denominator)
        return nil if division > MAXIMUM

        division
      end
    end
  end
end
