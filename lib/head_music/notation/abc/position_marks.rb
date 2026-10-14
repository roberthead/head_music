# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # The marks a voice places at a position rather than on a note: its own and
  # its part's dynamics. In each bar, a mark goes on the note or rest that
  # attacks at its position, on an invisible rest in an overlay of the bar
  # when it falls inside one, or on an invisible rest after the music when it
  # follows the last note.
  class PositionMarks
    Mark = Data.define(:position, :decoration, :label) do
      def offset
        PositionMarks.offset(position)
      end

      # Invisible rests can reach any offset in binary note values, but none
      # inside a tuplet.
      def reachable?
        !HeadMusic::Notation::DottedDuration.rhythmic_value_for(offset).nil?
      end
    end

    # One bar's marks by how each is written, with where its music ends and
    # its written length, as fractions of a whole note.
    BarMarks = Data.define(:attacks, :overlay, :trailing, :music_end, :length) do
      def decorations_at(position)
        attacks.fetch(position, []).map(&:decoration).join
      end

      def unreachable
        (overlay + trailing).find { |mark| !mark.reachable? }
      end
    end

    # The fraction of a whole note from the start of the bar.
    def self.offset(position)
      meter = position.meter
      ticks = position.tick + Rational(position.subtick, HeadMusic::Time::SUBTICKS_PER_TICK)
      (position.count - 1 + ticks / Rational(meter.ticks_per_count)) / meter.bottom_number
    end

    def initialize(voice)
      @flow = voice&.flow
      @marks = voice ? dynamic_marks(voice) : []
    end

    def bar_marks(bar_segments)
      bar_number = bar_segments.first.bar_number
      starts = bar_segments.map { |segment| segment_start(segment) }
      music_end = segment_end(bar_segments.last)
      attacks, others = @marks.select { |mark| mark.position.bar_number == bar_number }
        .partition { |mark| starts.include?(mark.position) }
      overlay, trailing = others.partition { |mark| mark.position < music_end }
      length = bar_length(bar_number)
      music_end_offset = (music_end.bar_number > bar_number) ? length : self.class.offset(music_end)
      BarMarks.new(attacks.group_by(&:position), overlay, trailing, music_end_offset, length)
    end

    private

    # A voice and its part with the same level at one position write it once.
    def dynamic_marks(voice)
      (voice.dynamic_events + voice.part.dynamic_events)
        .map { |event| Mark.new(event.position, "!#{event.name_key}!", "dynamic #{event.name_key}") }
        .uniq { |mark| [mark.position, mark.decoration] }
        .sort_by(&:position)
    end

    def segment_start(segment)
      position = segment.voice_event.position
      return position if segment.bar_number == position.bar_number

      @flow.position(segment.bar_number, 1, 0)
    end

    def segment_end(segment)
      segment.continues ? @flow.position(segment.bar_number + 1, 1, 0) : segment.voice_event.next_position
    end

    def bar_length(bar_number)
      meter = @flow.meter_at(bar_number)
      Rational(meter.top_number, meter.bottom_number)
    end
  end
end
