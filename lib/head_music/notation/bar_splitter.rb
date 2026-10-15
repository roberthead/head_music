module HeadMusic
  module Notation
    # Splits a voice event into one segment per bar it sounds in, for writers
    # that must write a note crossing a bar line as tied notes, one per bar.
    module BarSplitter
      # The fraction is of a whole note, and sounding: a tuplet piece's is
      # under its ratio. It is nil when the voice event fits its bar, so a
      # writer renders it from its own rhythmic value and keeps the tied chain
      # as authored. The offset is the exact onset of the piece in its bar, and
      # elapsed how much of the voice event comes before it.
      Segment = Data.define(:voice_event, :bar_number, :fraction, :continues, :offset, :elapsed) do
        def initialize(voice_event:, bar_number:, fraction:, continues:, offset: nil, elapsed: 0)
          super
        end

        # Nil when no binary note value, or tied chain of them, spans the
        # fraction under the value's ratio.
        def rhythmic_value
          return voice_event.rhythmic_value unless fraction

          value = voice_event.rhythmic_value
          return DottedDuration.rhythmic_value_for(fraction) unless value.tuplet?

          ratio = value.uniform_tuplet_ratio
          ratio ? DottedDuration.rhythmic_value_for(fraction, tuplet: ratio) : mixed_ratio_value
        end

        def rhythmic_value!(error_class)
          rhythmic_value || raise(error_class, "cannot express the part of the note at #{voice_event.position} " \
            "in bar #{bar_number} in binary note values#{under_ratio}")
        end

        private

        # A chain mixing ratios is cut link by link, each piece under its own.
        def mixed_ratio_value
          finish = elapsed + fraction
          pieces = BarSplitter.link_spans(voice_event).filter_map do |link, from, to|
            piece = [to, finish].min - [from, elapsed].max
            [piece, link.tuplet_ratio] if piece.positive?
          end
          values = pieces.map { |piece, ratio| DottedDuration.rhythmic_value_for(piece, tuplet: ratio) }
          values.reverse.reduce { |tail, head| head&.append_tied(tail) if tail } unless values.include?(nil)
        end

        def under_ratio
          ratio = voice_event.rhythmic_value.uniform_tuplet_ratio
          return "" unless ratio

          group = voice_event.voice.tuplet_at(voice_event.position)
          group ? " under the #{group}" : " under its #{ratio.to_a.join(":")} ratio"
        end
      end

      module_function

      def segments(voice_events)
        voice_events.flat_map { |voice_event| segments_of(voice_event) }
      end

      # Cut at the exact onset and length, so a rounded tuplet note splits
      # where its exact time crosses the barline.
      def segments_of(voice_event)
        bar_number, offset = exact_start(voice_event)
        length = voice_event.rhythmic_value.fraction
        elapsed = 0
        segments = []
        loop do
          room = bar_length(voice_event.flow, bar_number) - offset
          break if length - elapsed <= room

          segments << Segment.new(voice_event, bar_number, room, true, offset, elapsed)
          elapsed += room
          bar_number += 1
          offset = 0
        end
        segments << Segment.new(voice_event, bar_number, segments.empty? ? nil : length - elapsed, false, offset, elapsed)
      end

      # The exact onset of a voice event in the bar of its position, as a
      # fraction of a whole note. A rounded position's onset may lie up to half
      # a subtick from it.
      def onset_in_bar(voice_event)
        offset_in_bar(voice_event.position) +
          voice_event.onset_remainder / HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE
      end

      # The exact offset of a mark from its bar's start, as a fraction of a
      # whole note. Where a note starts at a rounded position, the mark is at
      # that note's exact onset, looked for first among the given voices.
      def mark_offset(flow, position, voices = [])
        voice_event = (voices + flow.voices).lazy.filter_map { |voice| voice.voice_event_at(position) }.first
        return offset_in_bar(position) unless voice_event

        onset_in_bar(voice_event)
      end

      # Each link of a voice event's chain with its exact start and end, as
      # fractions of a whole note from the event's onset.
      def link_spans(voice_event)
        from = 0
        voice_event.rhythmic_value.tied_chain.map do |link|
          to = from + link.link_fraction
          [link, from, to].tap { from = to }
        end
      end

      def bar_length(flow, bar_number)
        meter = flow.meter_at(bar_number)
        Rational(meter.top_number, meter.bottom_number)
      end

      # The bar and exact offset where a voice event begins. A rounded onset
      # just before a barline belongs to the bar before.
      def exact_start(voice_event)
        bar_number = voice_event.position.bar_number
        offset = onset_in_bar(voice_event)
        return [bar_number, offset] unless offset.negative?

        [bar_number - 1, offset + bar_length(voice_event.flow, bar_number - 1)]
      end

      def offset_in_bar(position)
        meter = position.meter
        ticks = position.tick + Rational(position.subtick, HeadMusic::Time::SUBTICKS_PER_TICK)
        (position.count - 1 + ticks / meter.ticks_per_count) / meter.bottom_number
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

      private_class_method :bar_length
    end
  end
end
