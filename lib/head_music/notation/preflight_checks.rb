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
