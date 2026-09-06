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

      def ensure_notes_within_barlines(flow)
        flow.voices.each do |voice|
          voice.placements.each do |placement|
            next unless placement.next_position > placement.position.start_of_next_bar

            raise render_error_class, "the note at #{placement.position} crosses its barline; " \
              "splitting notes across barlines is not supported"
          end
        end
      end

      def raise_gap_error(voice, expected_position, found_placement)
        if found_placement.equal?(voice.placements.first)
          raise render_error_class, "the first placement must start its bar " \
            "(found #{found_placement.position}); insert explicit rests to fill the gap"
        end

        raise render_error_class, "expected a placement at #{expected_position}, " \
          "found one at #{found_placement.position}; insert explicit rests to fill gaps"
      end
    end
  end
end
