module HeadMusic
  module Notation
    # Splits a voice event into one segment per bar it sounds in, for writers
    # that must write a note crossing a bar line as tied notes, one per bar.
    module BarSplitter
      # The fraction is of a whole note. It is nil when the voice event fits its
      # bar, so a writer renders it from its own rhythmic value and keeps the
      # tied chain as authored.
      Segment = Data.define(:voice_event, :bar_number, :fraction, :continues) do
        # Nil when no binary note value, or tied chain of them, spans the fraction.
        def rhythmic_value
          return voice_event.rhythmic_value unless fraction

          DottedDuration.rhythmic_value_for(fraction)
        end

        def rhythmic_value!(error_class)
          rhythmic_value || raise(
            error_class,
            "cannot express the part of the note at #{voice_event.position} in bar #{bar_number} in binary note values"
          )
        end
      end

      module_function

      def segments(voice_events)
        voice_events.flat_map { |voice_event| segments_of(voice_event) }
      end

      def segments_of(voice_event)
        start = voice_event.position
        finish = voice_event.next_position
        segments = []
        while finish > start.start_of_next_bar
          segments << Segment.new(voice_event, start.bar_number, fraction_to_bar_end(start), true)
          start = start.start_of_next_bar
        end
        fraction = segments.empty? ? nil : fraction_within_bar(start, finish)
        segments << Segment.new(voice_event, start.bar_number, fraction, false)
      end

      def fraction_to_bar_end(position)
        meter = position.meter
        Rational(meter.top_number, meter.bottom_number) - offset_in_bar(position)
      end

      # A voice event ending on a barline ends at offset zero of the next bar.
      def fraction_within_bar(from, to)
        return fraction_to_bar_end(from) if to == from.start_of_next_bar

        offset_in_bar(to) - offset_in_bar(from)
      end

      def offset_in_bar(position)
        meter = position.meter
        (position.count - 1 + Rational(position.tick, meter.ticks_per_count)) / meter.bottom_number
      end

      # The inverse of offset_in_bar: the position +offset+ of a whole note
      # into bar +bar_number+.
      def position_at(flow, bar_number, offset)
        meter = flow.meter_at(bar_number)
        counts = offset * meter.bottom_number
        ticks = (counts - counts.floor) * meter.ticks_per_count
        subticks = (ticks - ticks.floor) * HeadMusic::Time::SUBTICKS_PER_TICK
        flow.position(bar_number, counts.floor + 1, ticks.floor, subticks.round)
      end

      private_class_method :fraction_to_bar_end, :fraction_within_bar
    end
  end
end
