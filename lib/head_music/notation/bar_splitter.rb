module HeadMusic
  module Notation
    # Splits a placement into one segment per bar it sounds in, for writers
    # that must write a note crossing a bar line as tied notes, one per bar.
    module BarSplitter
      # The fraction is of a whole note. It is nil when the placement fits its
      # bar, so a writer renders it from its own rhythmic value and keeps the
      # tied chain as authored.
      Segment = Data.define(:placement, :bar_number, :fraction, :continues) do
        # Nil when no binary note value, or tied chain of them, spans the fraction.
        def rhythmic_value
          return placement.rhythmic_value unless fraction

          DottedDuration.rhythmic_value_for(fraction)
        end

        def rhythmic_value!(error_class)
          rhythmic_value || raise(
            error_class,
            "cannot express the part of the note at #{placement.position} in bar #{bar_number} in binary note values"
          )
        end
      end

      module_function

      def segments(placements)
        placements.flat_map { |placement| segments_of(placement) }
      end

      def segments_of(placement)
        start = placement.position
        finish = placement.next_position
        segments = []
        while finish > start.start_of_next_bar
          segments << Segment.new(placement, start.bar_number, fraction_to_bar_end(start), true)
          start = start.start_of_next_bar
        end
        fraction = segments.empty? ? nil : fraction_within_bar(start, finish)
        segments << Segment.new(placement, start.bar_number, fraction, false)
      end

      def fraction_to_bar_end(position)
        meter = position.meter
        Rational(meter.top_number, meter.bottom_number) - offset_in_bar(position)
      end

      # A placement ending on a barline ends at offset zero of the next bar.
      def fraction_within_bar(from, to)
        return fraction_to_bar_end(from) if to == from.start_of_next_bar

        offset_in_bar(to) - offset_in_bar(from)
      end

      def offset_in_bar(position)
        meter = position.meter
        (position.count - 1 + Rational(position.tick, meter.ticks_per_count)) / meter.bottom_number
      end

      private_class_method :fraction_to_bar_end, :fraction_within_bar
    end
  end
end
