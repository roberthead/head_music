module HeadMusic::MIDI
  # Reads fermatas, tempo ramps, and "a tempo" points back from a file's
  # tempo changes, as export writes them. Times are whole notes; a downbeat
  # is the start of a bar, and the end of the file is none.
  #
  # A fermata is a slower tempo, slower than the one before, restored within
  # one bar: to the tempo before, unless both changes fall on downbeats with
  # a note starting between them, which is a bar at another tempo, or
  # from a downbeat to a tempo held past the next, which changes the
  # tempo at that downbeat, unless it is the tempo a ramp ending there began
  # from, which is an "a tempo". A fermata may also be restored to the next
  # step of the ramp before it, that ramp's target, or, from within a bar,
  # to a new tempo at the next downbeat. The stretch is the ratio of the
  # slower tempo to the one it holds, to three decimals.
  #
  # A ramp is a run of changes all faster or all slower than the one before,
  # each a count or less after the one before, as export steps them, at
  # least two of them within a bar, whose last holds until the next
  # downbeat. It ramps from the tempo before the run to that last tempo. The
  # tempo at the very start begins no run.
  #
  # An "a tempo" is a change within a bar back to the tempo the latest ramp
  # began from.
  class TempoInference
    Ramp = Data.define(:from, :to, :microseconds, :start_microseconds) do
      def slowing?
        microseconds > start_microseconds
      end
    end

    Fermata = Data.define(:from, :to, :stretch)

    STRETCH_DECIMALS = 3

    attr_reader :changes, :ramps, :fermatas, :a_tempos

    # +changes+ are [time, microseconds] pairs in time order, each differing
    # from the one before, which is +opening+ before the first. +onsets+ are
    # the times notes start, sorted.
    def initialize(changes, layout, opening, onsets)
      @layout = layout
      @opening = opening
      @onsets = onsets
      @ramps = []
      @fermatas = []
      @a_tempos = []
      @changes = read_ramps(read_fermatas(changes))
    end

    private

    # The changes left once each fermata's pair is taken out, keeping the
    # tempo a fermata changes to at its downbeat, the next downbeat, or the
    # end of the ramp before it.
    def read_fermatas(changes)
      kept = []
      index = 0
      while index < changes.length
        start, restore = changes.values_at(index, index + 1)
        kind = restore && fermata_kind(start, restore, kept, changes[index + 2])
        if kind
          held = (kind == :restored) ? kept.last&.last || @opening : restore.last
          @fermatas << Fermata.new(start.first, restore.first, stretch(start.last, held))
          kept << [start.first, restore.last] if kind == :changed
          kept << restore if kind == :restored
          index += 2
        else
          kept << start
          index += 1
        end
      end
      kept
    end

    def fermata_kind(start, restore, kept, following)
      (from, slow), (to, tempo) = start, restore
      prior = kept.last&.last || @opening
      return unless slow > prior && slow > tempo && to - from <= @layout.bar_at(from).length

      if tempo == prior
        :held unless downbeat?(from) && downbeat?(to) && onset_between?(from, to)
      elsif downbeat?(from) && !downbeat?(to) && held?(to, following, through: true) && tempo != ramp_start(kept, start)
        :changed
      elsif held?(to, following) && continues_ramp?(kept, [from, tempo])
        :changed
      elsif !downbeat?(from) && downbeat?(to) && !continues_ramp?(kept, start)
        :restored
      end
    end

    # Whether +change+ is the next step of a ramp's run after the changes
    # kept.
    def continues_ramp?(kept, change)
      !kept.empty? && in_step?(kept.last, change) && !ramp_start(kept, change).nil?
    end

    # The tempo before the run of changes ending at +last+, if it is a ramp's.
    def ramp_start(kept, last)
      changes = [*kept, last]
      tempos = [@opening, *changes.map(&:last)]
      direction = tempos[-1] <=> tempos[-2]
      first = tempos.length - 1
      first -= 1 while first > 1 && (tempos[first - 1] <=> tempos[first - 2]) == direction && in_step?(changes[first - 2], changes[first - 1])
      run = changes.last(tempos.length - first)
      tempos[first - 1] if run.count { |time, _| !downbeat?(time) } >= 2
    end

    # Whether +after+ is a count or less after +before+, as steps under a
    # ramp are.
    def in_step?(before, after)
      after.first - before.first <= Rational(1, @layout.bar_at(before.first).meter.bottom_number)
    end

    def stretch(slow, tempo)
      ratio = Rational(slow, tempo).round(STRETCH_DECIMALS)
      (ratio.denominator == 1) ? ratio.to_i : ratio.to_f
    end

    # The changes left once each ramp's run is taken out but for its target.
    # A tempo at the very start is the opening one, not a change in a run.
    def read_ramps(changes)
      kept = []
      index = 0
      if changes.first&.first == @layout.bars.first.start
        kept << changes.first
        index = 1
      end
      while index < changes.length
        prior = kept.last&.last || @opening
        finish = run_end(changes, index, prior)
        if finish
          @ramps << Ramp.new(changes[index].first, *changes[finish], prior)
          kept << changes[finish]
          index = finish + 1
        else
          @a_tempos << changes[index].first if a_tempo?(*changes[index])
          kept << changes[index]
          index += 1
        end
      end
      kept
    end

    def run_end(changes, index, prior)
      direction = changes[index].last <=> prior
      finish = index
      finish += 1 while finish + 1 < changes.length && (changes[finish + 1].last <=> changes[finish].last) == direction && in_step?(*changes.values_at(finish, finish + 1))
      within_bars = changes[index..finish].count { |time, _| !downbeat?(time) }
      finish if within_bars >= 2 && held?(changes[finish].first, changes[finish + 1])
    end

    def a_tempo?(time, microseconds)
      ramp = ramps.last
      !ramp.nil? && !downbeat?(time) && microseconds == ramp.start_microseconds
    end

    def onset_between?(from, to)
      onset = @onsets.bsearch { |candidate| candidate > from }
      !onset.nil? && onset < to
    end

    def downbeat?(time)
      time < @layout.end_time && @layout.bar_at(time).start == time
    end

    # Whether a tempo at +time+ holds until the first downbeat at or after
    # it, or with +through+, past it.
    def held?(time, following, through: false)
      return true if following.nil? || downbeat?(time)

      through ? following.first > @layout.bar_at(time).end_time : following.first >= @layout.bar_at(time).end_time
    end
  end
end
