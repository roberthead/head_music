# frozen_string_literal: true

module HeadMusic
  module Time
    # Measures musical positions in subticks along a meter map, so a span that
    # crosses a meter change counts each bar in its own meter.
    class MeterScale
      Segment = Data.define(:position, :meter, :offset)

      def initialize(meter_map)
        @segments = []
        meter_map.events.each do |event|
          offset = @segments.empty? ? 0 : subticks_in(@segments.last, event.position)
          @segments << Segment.new(event.position, event.meter, offset)
        end
      end

      def subticks_at(position)
        position = MusicalPosition.new(*position.to_a) unless position.is_a?(MusicalPosition)
        subticks_in(segment_for(position), position)
      end

      def position_at(subticks)
        segment = segment_for_subticks(subticks)
        local = subticks - segment.offset + local_subticks(segment.position, segment.meter)
        per_count, per_bar = subtick_sizes(segment.meter)
        bar, remainder = local.divmod(per_bar)
        count, remainder = remainder.divmod(per_count)
        tick, subtick = remainder.divmod(HeadMusic::Time::SUBTICKS_PER_TICK)
        MusicalPosition.new(bar, count + 1, tick, subtick)
      end

      private

      def subticks_in(segment, position)
        segment.offset + local_subticks(position, segment.meter) - local_subticks(segment.position, segment.meter)
      end

      def segment_for(position)
        tuple = position.to_a
        index = @segments.bsearch_index { |segment| (segment.position.to_a <=> tuple).positive? }
        @segments[index ? [index - 1, 0].max : -1]
      end

      def segment_for_subticks(subticks)
        index = @segments.bsearch_index { |segment| segment.offset > subticks }
        @segments[index ? [index - 1, 0].max : -1]
      end

      def local_subticks(position, meter)
        per_count, per_bar = subtick_sizes(meter)
        position.bar * per_bar +
          (position.count - 1) * per_count +
          position.tick * HeadMusic::Time::SUBTICKS_PER_TICK +
          position.subtick
      end

      def subtick_sizes(meter)
        per_count = meter.ticks_per_count * HeadMusic::Time::SUBTICKS_PER_TICK
        [per_count, meter.counts_per_bar * per_count]
      end
    end
  end
end
