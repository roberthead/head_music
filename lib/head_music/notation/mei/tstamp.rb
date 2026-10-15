module HeadMusic::Notation::MEI
  # MEI's @tstamp, the beat in the bar counted from 1 in the meter's unit, and
  # @tstamp2, the bars later and the beat there, as "1m+3".
  module Tstamp
    module_function

    # How far into its measure a beat is, in whole notes.
    def offset(beat, meter)
      (beat - 1) / meter.bottom_number
    end

    # A control's @tstamp in its measure, or nil where it has none or names
    # a beat past the one after the measure's last. A value no beat could be
    # raises.
    def start(control, measure, **where)
      beat = AttributeValues.read(control, "tstamp", **where, element: control, count: AttributeValues::MAX_COUNT)
      beat if beat && beat <= measure.meter.top_number + 1
    end

    # A control's @tstamp2 as the index of the measure it reaches and the
    # beat there, or nil where it has none, no measure part, or reaches past
    # the music.
    def finish(control, measures, index, **where)
      value = XmlReading.attribute(control, "tstamp2", **where, element: control)
      return unless value&.include?("m+")

      bounds = {bars_left: AttributeValues::MAX_COUNT, count: AttributeValues::MAX_COUNT}
      bars, beat = AttributeValues.parse("tstamp2", value, **where, element: control, **bounds)
      target = measures[index + bars]
      [index + bars, beat] if target && beat <= target.meter.top_number + 1
    end

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
