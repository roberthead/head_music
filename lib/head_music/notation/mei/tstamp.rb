module HeadMusic::Notation::MEI
  # MEI's @tstamp, the beat in the bar counted from 1 in the meter's unit, and
  # @tstamp2, the bars later and the beat there, as "1m+3".
  module Tstamp
    module_function

    # A mark where a note starts takes that note's exact onset, looked for
    # first among the given voices.
    def beat(flow, position, voices = [])
      offset = HeadMusic::Notation::BarSplitter.mark_offset(flow, position, voices)
      Decimals.format(1 + offset * flow.meter_at(position.bar_number).bottom_number)
    end

    # The final barline, past the last written bar, is the beat after that
    # bar's last.
    def tstamp2(flow, from, to, voices = [])
      return "#{to.bar_number - from.bar_number}m+#{beat(flow, to, voices)}" if to < flow.final_barline_position

      last = flow.last_sounding_bar_number
      "#{last - from.bar_number}m+#{flow.meter_at(last).top_number + 1}"
    end
  end
end
