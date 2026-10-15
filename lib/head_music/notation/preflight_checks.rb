module HeadMusic
  module Notation
    # Whole-flow checks shared by the notation writers' preflights.
    # Each check raises before any output is assembled, so a caller that
    # passes them all can serialize without failing on these grounds; each
    # includer supplies its own format-specific RenderError subclass
    # through #render_error_class.
    module PreflightChecks
      # XML 1.0 forbids the C0 control characters other than tab, newline, and
      # carriage return, even as character references, and the noncharacters
      # U+FFFE and U+FFFF.
      FORBIDDEN_XML_CHARACTERS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFFFE\uFFFF]/

      private

      def ensure_xml_text(texts)
        texts.compact.map(&:to_s).each do |text|
          unless text.valid_encoding?
            raise render_error_class, "cannot render the invalid #{text.encoding} in #{text.inspect} as XML"
          end
          # The writers interpolate text into UTF-8 documents.
          unless text.ascii_only? || text.encoding == Encoding::UTF_8
            raise render_error_class, "cannot render #{text.inspect} as XML; encode it as UTF-8, not #{text.encoding}"
          end
          next unless text.match?(FORBIDDEN_XML_CHARACTERS)

          raise render_error_class, "cannot render the characters XML forbids in #{text.inspect}"
        end
      end

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

      # For a format whose tuplet brackets stop at a barline.
      def ensure_tuplets_within_bars(flow)
        flow.voices.each do |voice|
          bracket = HeadMusic::Notation::TupletBrackets.for(voice, error_class: render_error_class).find(&:crosses_barline?)
          next unless bracket

          raise render_error_class, "#{format_name} cannot write the #{bracket.label} " \
            "across the barline into bar #{bracket.bar_numbers[1]}"
        end
      end

      # A ratio such as 7:4 rounds its notes onto the subtick grid, so a mark
      # strictly inside one of them, where no note starts, lies at no exact
      # time a writer can say.
      def ensure_no_marks_inside_rounded_notes(flow)
        owned_timed_marks(flow).each do |voices, label, position|
          note = voices.lazy.filter_map { |voice| rounded_note_holding(voice, position) }.first
          next if note.nil? || exact_onset?(flow, position)

          raise render_error_class, "the #{label} at #{position} falls inside the #{note.rhythmic_value} at #{note.position}, " \
            "whose ratio does not land on whole subticks, where no note starts"
        end
      end

      # Each as [label, position, whether it is a hairpin's end].
      def timed_marks(flow)
        owned_timed_marks(flow).map { |_, *mark| mark }
      end

      # Each as [the voices it marks, label, position, whether it is a
      # hairpin's end].
      def owned_timed_marks(flow)
        [*flow.parts.map { |part| [part, part.voices] }, *flow.voices.map { |voice| [voice, [voice]] }]
          .flat_map { |owner, voices| owner_timed_marks(owner).map { |mark| [voices, *mark] } }
      end

      def owner_timed_marks(owner)
        levels = owner.dynamic_events.map { |event| ["dynamic #{event.name_key}", event.position, false] }
        hairpins = owner.spans.select(&:hairpin?)
        levels +
          hairpins.map { |span| ["#{span.name_key} start", span.from, false] } +
          hairpins.map { |span| ["#{span.name_key} end", span.to, true] }
      end

      def rounded_note_holding(voice, position)
        voice_event = voice.voice_event_sounding_at(position)
        return unless voice_event && voice_event.position < position

        voice_event if voice_event.rhythmic_value.tied_chain.any? { |link| link_rounds?(link) }
      end

      def exact_onset?(flow, position)
        flow.voices.any? { |voice| voice.voice_event_at(position)&.onset_remainder&.zero? }
      end

      def link_rounds?(link)
        (link.link_fraction * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE).denominator != 1
      end

      def format_name
        render_error_class.name.split("::")[-2]
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
