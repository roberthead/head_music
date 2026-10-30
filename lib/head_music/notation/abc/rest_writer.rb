# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # The rests a bar is filled with past its music, and in its overlay, each
  # carrying the marks at its offset.
  class RestWriter
    def initialize(duration_writer)
      @duration_writer = duration_writer
    end

    # A hairpin ending on the final barline goes on a spacer there, after
    # invisible rests that fill a short bar. A bar filled where the voice ends
    # early is filled with rests instead.
    def trailing(bar_marks, fill_to = nil)
      music_end = bar_marks.music_end
      length = bar_marks.length
      marks = bar_marks.trailing
      closing = bar_marks.closing.map(&:decoration).join
      rests =
        if fill_to && music_end < fill_to
          rests(music_end, fill_to, marks, "z")
        elsif marks.any? || (!closing.empty? && music_end < length)
          rests(music_end, length, marks, "x")
        end
      [rests, ("#{closing}y" unless closing.empty?)].compact.map { |text| " #{text}" }.join
    end

    def overlay(bar_marks)
      marks = bar_marks.overlay
      return "" if marks.empty?

      " & " + rests(0, bar_marks.trailing.empty? ? bar_marks.music_end : bar_marks.length, marks, "x")
    end

    private

    # From one offset to another, each mark on the rest starting at its
    # offset, "x" for an invisible one.
    def rests(from, to, marks, symbol)
      by_offset = marks.group_by(&:offset)
      starts = [from, *by_offset.keys].uniq
      starts.zip([*starts.drop(1), to]).map do |start, finish|
        "#{by_offset.fetch(start, []).map(&:decoration).join}#{symbol}#{rest_multiplier(finish - start)}"
      end.join(" ")
    end

    def rest_multiplier(fraction)
      @duration_writer.multiplier_string_for_fraction(fraction, HeadMusic::Notation::DottedDuration.rhythmic_duration_for(fraction))
    end
  end
end
