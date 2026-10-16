module HeadMusic::MIDI
  # Snaps the reader's notes to a grid of whole-note fractions.
  class Quantizer
    GRIDS = [Rational(1, 16), Rational(1, 24), Rational(1, 32), Rational(1, 48), Rational(1, 64), Rational(1, 96)].freeze

    attr_reader :layout, :division

    # +notes+ are the reader's Notes; +grid:+ is :auto or a positive Rational.
    def initialize(layout, notes, division:, grid: :auto)
      @layout = layout
      @source_notes = notes
      @division = division
      @requested_grid = grid
    end

    def grid
      @grid ||= (@requested_grid == :auto) ? GRIDS.first : @requested_grid
    end

    # In the order the notes were given.
    def notes
      @notes ||= @source_notes.map do |note|
        onset = snap(note.on)
        QuantizedNote.new(part_key: PartKey.for(note), key: note.key, onset: onset, release: [snap(note.off), onset + grid].max)
      end.freeze
    end

    # The grid point nearest a tick, for meta events such as lyrics.
    def snap(tick)
      (layout.time(tick) / grid).round * grid
    end
  end
end
