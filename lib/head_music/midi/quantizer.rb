module HeadMusic::MIDI
  # Snaps the reader's notes to a grid of whole-note fractions, measured from
  # each bar's downbeat. The automatic grid is the coarsest that places every
  # onset within a tick, since releases are often a tick or more early.
  class Quantizer
    GRIDS = [Rational(1, 16), Rational(1, 24), Rational(1, 32), Rational(1, 48), Rational(1, 64), Rational(1, 96)].freeze
    FINEST_GRID = Rational(1, 1024)
    TOLERANCE = 1
    FALLBACK_SHARE = Rational(99, 100)

    def self.check_grid(grid)
      return grid if grid == :auto
      raise ArgumentError, "grid: takes :auto or a positive Rational, not #{grid.inspect}" unless grid.is_a?(Rational) && grid.positive?
      raise ArgumentError, "grid: #{grid} is finer than #{FINEST_GRID}" if grid < FINEST_GRID

      grid
    end

    attr_reader :layout, :division

    # +notes+ are the reader's Notes; +grid:+ is :auto or a positive Rational.
    def initialize(layout, notes, division:, grid: :auto)
      @layout = layout
      @source_notes = notes
      @division = division
      @requested_grid = self.class.check_grid(grid)
    end

    def grid
      @grid ||= (@requested_grid == :auto) ? automatic_grid : @requested_grid
    end

    # In the order the notes were given. A release less than a step before
    # the next onset in its part reaches that onset.
    def notes
      @notes ||= @source_notes.map do |note|
        onset = snap(note.on)
        following = next_onset(note)
        release = (following && following - note.off < step_ticks) ? snap(following) : snap(note.off)
        QuantizedNote.new(part_key: PartKey.for(note), key: note.key, onset: onset, release: [release, onset + grid].max)
      end.freeze
    end

    # The grid point nearest a tick, measured from its bar's downbeat and
    # rounding half up, for onsets, releases, and meta events such as lyrics.
    def snap(tick)
      bar, offset = placement(tick)
      bar.start + snapped_offset(bar, offset, grid)
    end

    private

    def ticks_per_whole
      division * 4
    end

    def step_ticks
      grid * ticks_per_whole
    end

    # The coarsest grid that places every onset within a tick, or else the
    # coarsest that places nearly as many as the best grid does.
    def automatic_grid
      placements = @source_notes.map { |note| placement(note.on) }
      counts = GRIDS.map { |candidate| placements.count { |bar, offset| fits?(bar, offset, candidate) } }
      enough = (counts.max == placements.length) ? placements.length : FALLBACK_SHARE * counts.max
      GRIDS[counts.index { |count| count >= enough }]
    end

    def fits?(bar, offset, candidate)
      ((offset - snapped_offset(bar, offset, candidate)) * ticks_per_whole).abs <= TOLERANCE
    end

    # The next downbeat is a grid point too, and nearer than any past it.
    def snapped_offset(bar, offset, step)
      [nearest_step(offset, step) * step, bar.length].min
    end

    # The bar holding a tick and the tick's Rational offset from its downbeat.
    def placement(tick)
      time = layout.time(tick)
      bar = layout.bar_at(time)
      [bar, time - bar.start]
    end

    # floor(offset / step + 1/2), in integers.
    def nearest_step(offset, step)
      numerator = offset.numerator * step.denominator
      denominator = offset.denominator * step.numerator
      (2 * numerator + denominator).div(2 * denominator)
    end

    # The earliest onset in the note's part after its own and at or after its
    # release, in ticks.
    def next_onset(note)
      onsets = onsets_by_part[PartKey.for(note)]
      earliest = [note.off, note.on + 1].max
      onsets.bsearch { |on| on >= earliest }
    end

    def onsets_by_part
      @onsets_by_part ||= @source_notes.group_by { |note| PartKey.for(note) }.transform_values { |notes| notes.map(&:on).uniq.sort }
    end
  end
end
