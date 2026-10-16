module HeadMusic::MIDI
  # Writes spans of Rational whole notes as rhythmic values in the layout's
  # bars.
  class NoteValues
    MAX_PIECE = HeadMusic::Notation::DottedDuration::MAX_FRACTION

    attr_reader :layout

    def initialize(layout)
      @layout = layout
    end

    # One rhythmic value, a tied chain where no single value fits, for a note
    # from its onset to its release. It is cut at barlines, and at beats where
    # its length within a bar is not binary.
    def value(onset, release)
      values = bar_segments(onset, release).flat_map do |bar, from, to|
        pieces = binary?(to - from) ? [[from, to]] : beat_pieces(bar, from, to)
        pieces.map { |start, finish| piece_value(bar, start, finish) }
      end
      raise UnsupportedFeatureError, "no rhythmic value spans #{release - onset} of a whole note" if values.empty?

      values.reverse.reduce { |tail, head| head.append_tied(tail) }
    end

    # The rests filling a gap, each with the time it starts at. A whole empty
    # bar is one rest, and a gap within a bar is cut at beats.
    def rests(from, to)
      bar_segments(from, to).flat_map do |bar, start, finish|
        rest_pieces(bar, start, finish).map { |piece_start, piece_end| [piece_start, piece_value(bar, piece_start, piece_end)] }
      end
    end

    private

    def bar_segments(from, to)
      segments = []
      while from < to
        bar = bar_containing(from)
        segment_end = [bar.end_time, to, from + MAX_PIECE].min
        segments << [bar, from, segment_end]
        from = segment_end
      end
      segments
    end

    # Past the last bar, bars of its length and meter go on.
    def bar_containing(time)
      bar = layout.bar_at(time)
      return bar if time < bar.end_time

      skipped = ((time - bar.end_time) / bar.length).floor
      bar.with(number: bar.number + skipped + 1, start: bar.end_time + (skipped * bar.length))
    end

    def rest_pieces(bar, from, to)
      return [[from, to]] if from == bar.start && to == bar.end_time

      anchor, beat = beat_grid(bar)
      beat_pieces(bar, from, to).flat_map do |start, finish|
        on_beats = [start, finish].all? { |time| ((time - anchor) / beat).denominator == 1 }
        on_beats ? aligned_beats(start, finish, anchor, beat) : [[start, finish]]
      end
    end

    # Whole beats as the longest single values that each start at a multiple
    # of their own length from the downbeat.
    def aligned_beats(from, to, anchor, beat)
      pieces = []
      while from < to
        offset = (from - anchor) / beat
        count = ((to - from) / beat).to_i.downto(1).find { |beats| (offset % beats).zero? && single?(beats * beat) }
        pieces << [from, from + (count * beat)]
        from += count * beat
      end
      pieces
    end

    def single?(duration)
      value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(duration)
      value && !value.tied_value
    end

    # The beat and the downbeat its bar counts from. A short bar is the end of
    # a full one, so its downbeat lies before its start.
    def beat_grid(bar)
      nominal = Rational(bar.meter.top_number, bar.meter.bottom_number)
      anchor = (bar.length < nominal) ? bar.end_time - nominal : bar.start
      [anchor, BarLayout.beat(bar.meter).fraction]
    end

    # The partial beat before the first beat inside the span, the whole beats,
    # and the partial beat after them.
    def beat_pieces(bar, from, to)
      anchor, beat = beat_grid(bar)
      first_beat = anchor + (((from - anchor) / beat).ceil * beat)
      last_beat = anchor + (((to - anchor) / beat).floor * beat)
      return [[from, to]] if first_beat >= to

      [[from, first_beat], [first_beat, last_beat], [last_beat, to]].select { |start, finish| finish > start }
    end

    def piece_value(bar, from, to)
      duration = to - from
      tuplet = HeadMusic::Notation::DottedDuration.tuplet_ratio(duration)
      HeadMusic::Notation::DottedDuration.rhythmic_value_for(duration, tuplet: tuplet) ||
        raise(UnsupportedFeatureError, "no rhythmic value spans #{duration} of a whole note in bar #{bar.number}")
    end

    def binary?(duration)
      HeadMusic::Notation::DottedDuration.power_of_two?(duration.denominator)
    end
  end
end
