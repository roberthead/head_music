module HeadMusic
  module Notation
    # Splits one voice's noteheads in one bar into beam groups, for any
    # writer. An event's levels are the beams it carries alone (eighth 1,
    # sixteenth 2, ...), 0 for a rest or a quarter or longer; its onset is
    # its offset in the bar as a fraction of a whole note; and its
    # beam_break_before is the authored override against the previous event
    # (nil for the meter's default, true to break, false to join).
    module BeamGroups
      Event = Data.define(:levels, :onset, :beam_break_before)

      module_function

      # A beat longer than any note value, as in 12/1, beams nothing.
      def group_start?(onset, meter)
        unit = meter.beam_group_unit
        return true unless unit&.unit

        (onset % DottedDuration.dotted_unit_fraction(unit)).zero?
      end

      # Arrays of consecutive event indices, one per group. A lone event is a
      # group of its own.
      def groups(events, meter)
        events.each_index.slice_before { |index| index.zero? || break_before?(events, index, meter) }.to_a
      end

      def break_before?(events, index, meter)
        event = events[index]
        return true if event.levels.zero? || events[index - 1].levels.zero?
        override = event.beam_break_before
        return override if [true, false].include?(override)

        group_start?(event.onset, meter)
      end
      private_class_method :break_before?
    end
  end
end
