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
      # writer would have to invent empty bars to reach one outside them. A
      # hairpin may also end on the final barline, as one ending with the
      # music does.
      def ensure_timed_marks_within_music(flow)
        first = flow.earliest_bar_number
        last = flow.last_sounding_bar_number
        final_barline = flow.final_barline_position
        timed_marks(flow).sort_by { |_, position| position }.each do |label, position, ending|
          if position.bar_number < first
            raise render_error_class, "the #{label} at #{position} falls before the music starts in bar #{first}"
          elsif ending ? position > final_barline : position.bar_number > last
            raise render_error_class, "the #{label} at #{position} falls after the music ends in bar #{last}"
          end
        end
      end

      # For a format with one line of hairpins for several owners, such as a
      # part and its voices. The same hairpin twice loses only its owner.
      def ensure_one_hairpin_at_a_time(spans, line:)
        hairpins = spans.select(&:hairpin?).uniq(&:to_h).sort
        hairpins.combination(2).each do |one, other|
          next unless one.from < other.to && other.from < one.to

          raise render_error_class, "#{line} holds one hairpin at a time, so the #{one} and the #{other} cannot both be written"
        end
      end

      # For a format with one line of dynamics for several owners, such as a
      # part and its voices. The same level twice loses only its owner.
      def ensure_one_level_per_position(owners, line:)
        dynamic_events = owners.flat_map(&:dynamic_events)
        dynamic_events.group_by(&:position).sort_by(&:first).each do |position, events|
          levels = events.map(&:name_key).uniq
          next if levels.one?

          raise render_error_class, "#{line} holds one dynamic at a time, " \
            "so the #{levels.join(" and the ")} at #{position} cannot both be written"
        end
      end

      # Each as [label, position, whether it is a hairpin's end].
      def timed_marks(flow)
        owners = flow.parts + flow.voices
        levels = owners.flat_map(&:dynamic_events).map { |event| ["dynamic #{event.name_key}", event.position, false] }
        hairpins = owners.flat_map(&:spans).select(&:hairpin?)
        levels +
          hairpins.map { |span| ["#{span.name_key} start", span.from, false] } +
          hairpins.map { |span| ["#{span.name_key} end", span.to, true] }
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
