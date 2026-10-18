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

      # The text every XML writer takes from a flow, beside what only some
      # write.
      def flow_texts(flow)
        [
          flow.name, flow.composer, flow.work&.title,
          *flow.voices.map(&:role),
          *flow.bars(flow.last_sounding_bar_number).map(&:rehearsal_mark),
          *flow.voices.flat_map { |voice| voice.voice_events.flat_map { |event| event.syllables.values.map(&:text) } }
        ]
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
      # writer would have to invent empty bars to reach one outside them.
      def ensure_timed_marks_within_music(flow)
        first = flow.earliest_bar_number
        last = flow.last_sounding_bar_number
        final_barline = flow.final_barline_position
        FlowTimedMarks.new(flow).sort_by(&:position).each do |mark|
          if mark.position.bar_number < first
            raise render_error_class, "the #{mark} falls before the music starts in bar #{first}"
          elsif mark.after?(last, final_barline)
            raise render_error_class, "the #{mark} falls after the music ends in bar #{last}"
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
        FlowTimedMarks.new(flow).each do |mark|
          note = mark.rounded_note
          next if note.nil? || exact_onset?(flow, mark.position)

          raise render_error_class, "the #{mark} falls inside the #{note.rhythmic_value} at #{note.position}, " \
            "whose ratio does not land on whole subticks, where no note starts"
        end
      end

      def exact_onset?(flow, position)
        flow.voices.any? { |voice| voice.voice_event_at(position)&.onset_remainder&.zero? }
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
