# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # The computed musical facts a Writer needs to serialize a flow:
  # the tokens for every voice event in each bar it sounds in, on top of the measure signatures the base
  # plan tracks. Construction eagerly computes everything that can raise
  # on unmappable keys, durations, or alterations, so a RenderPlan that builds successfully
  # cannot fail assembly on those grounds.
  class RenderPlan < HeadMusic::Notation::RenderPlan
    def tokens_by_segment
      @tokens_by_segment ||= flow.voices.flat_map { |voice| segments_by_bar(voice).values.flatten }.to_h do |segment|
        [segment, token(segment)]
      end
    end

    # The length, as a fraction of a whole note, of a final bar that every
    # voice ends short of together, or nil where the final bar is written
    # full: where the music fills it, or where a mark follows the music in it.
    def short_final_bar_fraction
      music_end_fraction unless trailing_marks?
    end

    # Where in the final bar every voice's music ends together, or nil where
    # it ends at the barline.
    def music_end_fraction
      return @music_end_fraction if defined?(@music_end_fraction)

      offset = music_end && HeadMusic::Notation::BarSplitter.offset_in_bar(music_end)
      @music_end_fraction = (offset && !offset.zero?) ? offset : nil
    end

    # Whether a short final bar is written full, so marks after the music have
    # spacers to go on.
    def filled_final_bar?(bar_number)
      bar_number == bar_numbers.last && trailing_marks?
    end

    # The spacers that fill a short final bar after the voice's music, carrying
    # its marks there. A nil voice is a staff nobody is written on.
    def trailing_spacers(voice)
      @trailing_spacers ||= {}.compare_by_identity
      @trailing_spacers[voice] ||= begin
        bar_number = bar_numbers.last
        spacer_run(bar_number, music_end_fraction, bar_length(bar_number), timed_marks(voice).trailing(bar_number, music_end_fraction))
      end
    end

    # What a part's \new Dynamics says in each bar: spacers that reach each of
    # its levels at the level's exact position.
    def dynamics_bars(part)
      @dynamics_bars ||= {}.compare_by_identity
      @dynamics_bars[part] ||= begin
        events_by_bar = part.dynamic_events.group_by { |event| event.position.bar_number }
        bar_numbers.to_h { |bar_number| [bar_number, dynamics_bar(bar_number, events_by_bar.fetch(bar_number, []))] }
      end
    end

    # A part's own dynamics are written in a \new Dynamics, so only the voice's
    # are placed among its links. A nil voice is a staff nobody is written on.
    def timed_marks(voice)
      @timed_marks ||= {}.compare_by_identity
      @timed_marks[voice] ||= voice ? TimedMarks.voice(voice) : TimedMarks.new([])
    end

    # What ends a hairpin on the final barline, after the owner's last link or
    # spacer: \after there prints "no broken bound" for a level, and a marker
    # with no duration reaches it cleanly.
    def final_barline_marks(owner)
      final_barline = flow.final_barline_position
      "<>\\!" if owner&.spans&.any? { |span| span.hairpin? && span.to == final_barline }
    end

    private

    def precompute_eager_data
      super
      tokens_by_segment
      flow.parts.each { |part| dynamics_bars(part) unless part.dynamic_events.empty? }
      [nil, *flow.voices].each { |voice| trailing_spacers(voice) } if trailing_marks?
    end

    def music_end
      return @music_end if defined?(@music_end)

      @music_end = flow.voices.filter_map { |voice| voice.last_voice_event&.next_position }.max
    end

    def trailing_marks?
      return @trailing_marks if defined?(@trailing_marks)

      @trailing_marks = !music_end_fraction.nil? && (
        flow.parts.any? { |part| part.dynamic_events.any? { |event| event.position >= music_end } } ||
        flow.voices.any? { |voice| timed_marks(voice).trailing(bar_numbers.last, music_end_fraction).any? }
      )
    end

    def dynamics_bar(bar_number, events)
      marks = events.map { |event| TimedMarks.mark(event.position, "\\#{event.level.name_key}", "dynamic #{event.name_key}") }
      spacer_run(bar_number, 0r, bar_length(bar_number), marks)
    end

    # Spacers from one offset in the bar to another, each mark on the first
    # spacer where it falls.
    def spacer_run(bar_number, from, to, marks)
      marks_by_offset = marks.group_by(&:offset)
      [from, *marks_by_offset.keys.sort, to].uniq.each_cons(2).flat_map { |start, finish|
        first, *later = spacers(finish - start) || raise_unreachable(bar_number, marks_by_offset[finish] || marks_by_offset[start])
        ["#{first}#{marks_by_offset.fetch(start, []).map(&:token).join}", *later]
      }.join(" ")
    end

    def raise_unreachable(bar_number, marks)
      subject = marks ? "the #{marks.first.label}" : "the dynamics in bar #{bar_number}"
      raise RenderError, "cannot place #{subject} in LilyPond output: no binary note value reaches it"
    end

    def bar_length(bar_number)
      return short_final_bar_fraction if bar_number == bar_numbers.last && short_final_bar_fraction

      meter = effective_meter(bar_number)
      Rational(meter.top_number, meter.bottom_number)
    end

    def spacers(fraction)
      HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction)&.tied_chain&.map { |link| "s#{DurationWriter.token(link)}" }
    end

    # LilyPond has no way to say "three flats read as dorian", so it renders
    # what is printed at the clef.
    def key_value(event)
      KeyMapper.token(event.printed_key_signature)
    end

    # A tied chain within a voice event joins its links with the tie mark, and
    # so does a voice event split at a barline, whose piece before the bar check
    # ends in one; a chain of rests emits consecutive untied rests, and a tied
    # chord repeats the whole chord. Each link carries the voice's levels and
    # hairpin marks that fall in it, and only the first the voice event's own
    # marks, after any hairpin ending there and before any starting.
    # A slur closes on the last link and opens on the first, closing first
    # where they are one word, so one slur can end where the next begins. A
    # rest reads back as one rest per link, so it carries both on its first.
    def token(segment)
      voice_event = segment.voice_event
      words = link_words(segment)
      words[closes_index(segment, words)] += span_marks(voice_event).closes_at(voice_event.position) if closes?(segment)
      words[0] += span_marks(voice_event).opens_at(voice_event.position) if starts?(segment)
      return words.join(" ") if voice_event.rest?

      tokens = words.join("~ ")
      segment.continues ? "#{tokens}~" : tokens
    end

    def link_words(segment)
      voice_event = segment.voice_event
      marks = timed_marks(voice_event.voice)
      bar_number = segment.bar_number
      from = starts?(segment) ? HeadMusic::Notation::BarSplitter.offset_in_bar(voice_event.position) : 0r
      own = starts?(segment) ? MarkWriter.token(voice_event) : ""
      segment.rhythmic_value!(RenderError).tied_chain.map do |link|
        to = from + HeadMusic::Notation::DottedDuration.dotted_unit_fraction(link)
        word = marks.around(bar_number, from, to, "#{body(voice_event)}#{DurationWriter.token(link)}", own)
        from = to
        own = ""
        word
      end
    end

    def body(voice_event)
      return "r" if voice_event.rest?

      voice_event.chord? ? chord_body(voice_event) : PitchWriter.token(voice_event.pitch)
    end

    def closes?(segment)
      segment.voice_event.rest? ? starts?(segment) : !segment.continues
    end

    def closes_index(segment, words)
      segment.voice_event.rest? ? 0 : words.length - 1
    end

    def starts?(segment)
      segment.bar_number == segment.voice_event.position.bar_number
    end

    def span_marks(voice_event)
      @span_marks ||= {}.compare_by_identity
      @span_marks[voice_event.voice] ||= SpanMarks.new(voice_event.voice)
    end

    def chord_body(voice_event)
      "<#{voice_event.pitches.sort.map { |pitch| PitchWriter.token(pitch) }.join(" ")}>"
    end
  end
end
