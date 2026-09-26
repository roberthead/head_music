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
