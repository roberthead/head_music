module HeadMusic::MIDI
  # Cuts a sounding interval at the barlines it crosses, since each bar is
  # placed in the file wherever the performance order plays it. Offsets are
  # exact whole notes into the piece's bar.
  module BarPieces
    Piece = Data.define(:bar_number, :from, :to, :joins_previous, :continues)

    module_function

    # +from+ and +to+ are relative to the voice event's exact onset.
    def of(voice_event, from, to)
      bar_number, offset = HeadMusic::Notation::BarSplitter.exact_start(voice_event)
      cut(voice_event.flow, bar_number, offset + from, offset + to)
    end

    # +from+ and +to+ are offsets into bar +bar_number+, and may run past it.
    def cut(flow, bar_number, from, to)
      pieces = []
      return pieces unless to > from

      length = PerformanceTimeline.bar_length(flow, bar_number)
      while from >= length
        from -= length
        to -= length
        bar_number += 1
        length = PerformanceTimeline.bar_length(flow, bar_number)
      end
      loop do
        continues = to > length
        pieces << Piece.new(bar_number, from, continues ? length : to, pieces.any?, continues)
        break unless continues

        to -= length
        from = 0
        bar_number += 1
        length = PerformanceTimeline.bar_length(flow, bar_number)
      end
      pieces
    end
  end
end
