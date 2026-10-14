module HeadMusic
  module Notation
    # Whole-flow checks shared by the notation writers' preflights.
    # Each check raises before any output is assembled, so a caller that
    # passes them all can serialize without failing on these grounds; each
    # includer supplies its own format-specific RenderError subclass
    # through #render_error_class.
    module PreflightChecks
      private

      def ensure_contiguous_voices(flow)
        flow.voices.each do |voice|
          gap = voice.first_gap
          raise_gap_error(voice, *gap) if gap
        end
      end

      # Writers write the bars the music reaches, so a marking on a later bar
      # would be lost.
      def ensure_markings_within_music(flow)
        marked = flow.last_marked_bar_number
        last = flow.last_sounding_bar_number
        return unless marked && marked > last

        raise render_error_class, "bar #{marked} carries repeat structure or markings, but the music ends in bar #{last}"
      end

      # A mark that takes no time can sit anywhere in the written bars, but a
      # writer would have to invent empty bars to reach one outside them.
      def ensure_timed_marks_within_music(flow)
        first = flow.earliest_bar_number
        last = flow.last_sounding_bar_number
        timed_marks(flow).sort_by(&:last).each do |label, position|
          if position.bar_number < first
            raise render_error_class, "the #{label} at #{position} falls before the music starts in bar #{first}"
          elsif position.bar_number > last
            raise render_error_class, "the #{label} at #{position} falls after the music ends in bar #{last}"
          end
        end
      end

      def timed_marks(flow)
        (flow.parts + flow.voices).flat_map(&:dynamic_events).map do |dynamic_event|
          ["dynamic #{dynamic_event.name_key}", dynamic_event.position]
        end
      end

      def raise_gap_error(voice, expected_position, found_voice_event)
        if found_voice_event.equal?(voice.voice_events.first)
          raise render_error_class, "the first voice event must start its bar " \
            "(found #{found_voice_event.position}); insert explicit rests to fill the gap"
        end

        raise render_error_class, "expected a voice event at #{expected_position}, " \
          "found one at #{found_voice_event.position}; insert explicit rests to fill gaps"
      end
    end
  end
end
