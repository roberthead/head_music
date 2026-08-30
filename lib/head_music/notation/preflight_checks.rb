module HeadMusic
  module Notation
    # Whole-composition checks shared by the notation writers' preflights.
    # Each check raises before any output is assembled, so a caller that
    # passes them all can serialize without failing on these grounds; each
    # includer supplies its own format-specific RenderError subclass
    # through #render_error_class.
    module PreflightChecks
      private

      # change_meter and change_key_signature store the caller's raw value
      # (Bar's accessors are bare attr_accessors), and Position arithmetic
      # breaks on an un-coerced meter string, so markers are normalized in
      # place before any placement's next_position is computed.
      def normalize_bar_markers(composition)
        composition.bars.each do |bar|
          bar.meter = HeadMusic::Rudiment::Meter.get(bar.meter) if bar.meter
          bar.key_signature = HeadMusic::Rudiment::KeySignature.get(bar.key_signature) if bar.key_signature
        end
      end

      def ensure_contiguous_voices(composition)
        composition.voices.each do |voice|
          gap = voice.first_gap
          raise_gap_error(voice, *gap) if gap
        end
      end

      def ensure_notes_within_barlines(composition)
        composition.voices.each do |voice|
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
