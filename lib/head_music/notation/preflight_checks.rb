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
        texts.compact.each do |text|
          problem = xml_text_problem(text.to_s)
          raise render_error_class, problem if problem
        end
      end

      # The writers interpolate text into UTF-8 documents.
      def xml_text_problem(text)
        encoding = text.encoding
        if !text.valid_encoding?
          "cannot render the invalid #{encoding} in #{text.inspect} as XML"
        elsif !(text.ascii_only? || encoding == Encoding::UTF_8)
          "cannot render #{text.inspect} as XML; encode it as UTF-8, not #{encoding}"
        elsif text.match?(FORBIDDEN_XML_CHARACTERS)
          "cannot render the characters XML forbids in #{text.inspect}"
        end
      end

      # The text every XML writer takes from a flow, beside what only some
      # write.
      def flow_texts(flow)
        voices = flow.voices
        [
          flow.name, flow.composer, flow.work&.title,
          *voices.map(&:role),
          *flow.bars(flow.last_sounding_bar_number).map(&:rehearsal_mark),
          *voices.flat_map(&:voice_events).flat_map { |event| event.syllables.values }.map(&:text)
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
        one, other = hairpins.combination(2).find { |earlier, later| earlier.from < later.to && later.from < earlier.to }
        raise_crowded(line, "hairpin", "#{one} and the #{other}") if one
      end

      # For a format with one line of dynamics for several owners, such as a
      # part and its voices. The same level twice loses only its owner.
      def ensure_one_level_per_position(owners, line:)
        dynamic_events = owners.flat_map(&:dynamic_events)
        dynamic_events.group_by(&:position).sort_by(&:first).each do |position, events|
          levels = events.map(&:name_key).uniq
          raise_crowded(line, "dynamic", "#{levels.join(" and the ")} at #{position}") unless levels.one?
        end
      end

      def raise_crowded(line, kind, clash)
        raise render_error_class, "#{line} holds one #{kind} at a time, so the #{clash} cannot both be written"
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
        found = found_voice_event.position
        message =
          if found_voice_event.equal?(voice.voice_events.first)
            "the first voice event must start its bar (found #{found}); insert explicit rests to fill the gap"
          else
            "expected a voice event at #{expected_position}, found one at #{found}; insert explicit rests to fill gaps"
          end
        raise render_error_class, message
      end
    end
  end
end
