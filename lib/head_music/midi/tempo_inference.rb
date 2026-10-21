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
      def text
        (microseconds > start_microseconds) ? "rit." : "accel."
      end
    end

    Fermata = Data.define(:from, :to, :stretch)

    STRETCH_DECIMALS = 3

    attr_reader :changes, :ramps, :fermatas, :a_tempos

    # +changes+ are [time, microseconds] pairs in time order, each differing
    # from the one before, which is +opening+ before the first. +onsets+ are
    # the Onsets of the notes.
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

    # The changes left once each fermata's pair is replaced by the tempo
    # under it at its start and the tempo it is restored to at its end, each
    # kept only where it differs from the one before.
    def read_fermatas(changes)
      kept = TempoChanges.new(@layout, @opening)
      index = 0
      while index < changes.length
        start, restore = changes.values_at(index, index + 1)
        under = restore && tempo_under(start, restore, kept, changes[index + 2])
        @fermatas << Fermata.new(start.first, restore.first, stretch(start.last, under)) if under
        taken = under ? [[start.first, under], restore] : [start]
        taken.each { |change| kept << change }
        index += taken.length
      end
      kept
    end

    # The tempo a fermata from +start+ to +restore+ holds, if it is one.
    def tempo_under(start, restore, kept, following)
      (from, slow), (to, tempo) = start, restore
      prior = kept.tempo_before
      return unless slow > prior && slow > tempo && to - from <= @layout.bar_at(from).length

      on_from, on_to = @layout.downbeat?(from), @layout.downbeat?(to)
      if tempo == prior
        prior unless on_from && on_to && @onsets.between?(from, to)
      elsif (on_from && !on_to && held?(to, following, through: true) && tempo != ramp_start(kept, start)) || (held?(to, following) && continues_ramp?(kept, [from, tempo]))
        tempo
      elsif !on_from && on_to && !continues_ramp?(kept, start)
        prior
      end
    end

    # Whether +change+ is the next step of a ramp's run after the changes
    # kept.
    def continues_ramp?(kept, change)
      !ramp_start(kept, change).nil?
    end

    # The tempo before the run of changes ending at +last+, if it is a ramp's.
    def ramp_start(kept, last)
      changes = kept.with(last)
      run = changes.run(kept.length, -1)
      changes.tempo_before(run.begin) if changes.ramp?(run)
    end

    # The changes left once each ramp's run is taken out but for its target.
    # A tempo at the very start is the opening one, not a change in a run.
    def read_ramps(changes)
      index = (changes.first&.first == 0) ? 1 : 0
      kept = changes.first(index)
      while index < changes.length
        finish = ramp_end(changes, index)
        if finish
          @ramps << Ramp.new(changes[index].first, *changes[finish], changes.tempo_before(index))
        elsif a_tempo?(*changes[index])
          @a_tempos << changes[index].first
        end
        index = finish || index
        kept << changes[index]
        index += 1
      end
      kept
    end

    def ramp_end(changes, index)
      finish = changes.run(index, 1).end
      finish if changes.ramp?(index..finish) && held?(changes[finish].first, changes[finish + 1])
    end

    def stretch(slow, tempo)
      ratio = Rational(slow, tempo).round(STRETCH_DECIMALS)
      (ratio.denominator == 1) ? ratio.to_i : ratio.to_f
    end

    def a_tempo?(time, microseconds)
      ramp = ramps.last
      !ramp.nil? && !@layout.downbeat?(time) && microseconds == ramp.start_microseconds
    end

    # Whether a tempo at +time+ holds until the first downbeat at or after
    # it, or with +through+, past it.
    def held?(time, following, through: false)
      return true if following.nil? || @layout.downbeat?(time)

      through ? following.first > @layout.bar_at(time).end_time : following.first >= @layout.bar_at(time).end_time
    end
  end
end
