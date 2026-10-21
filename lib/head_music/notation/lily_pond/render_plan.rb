# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # The computed musical facts a Writer needs to serialize a flow:
  # the tokens for every voice event in each bar it sounds in, on top of the measure signatures the base
  # plan tracks. Construction eagerly computes everything that can raise
  # on unmappable keys, durations, or alterations, so a RenderPlan that builds successfully
  # cannot fail assembly on those grounds.
  class RenderPlan < HeadMusic::Notation::RenderPlan
    def tokens_by_segment
      @tokens_by_segment ||= flow.voices.each_with_object({}) { |voice, tokens| tokens.merge!(segment_tokens(voice).to_h) }
    end

    def tuplet_edges(voice)
      segment_tokens(voice).tuplet_edges
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
        SpacerRun.new(bar_number, music_end_fraction, bar_length(bar_number), timed_marks(voice).trailing(bar_number, music_end_fraction)).to_s
      end
    end

    # What a part's \new Dynamics says in each bar: spacers that reach each of
    # its levels and hairpin marks at their exact positions.
    def dynamics_bars(part)
      @dynamics_bars ||= {}.compare_by_identity
      @dynamics_bars[part] ||= bar_numbers.to_h do |bar_number|
        text = SpacerRun.new(bar_number, 0r, bar_length(bar_number), part_marks(part).trailing(bar_number, 0r)).to_s
        [bar_number, [text, (bar_number == bar_numbers.last) ? final_barline_marks(part) : nil].compact.join(" ")]
      end
    end

    # Whether a part has a \new Dynamics to write.
    def dynamics?(part)
      !part.dynamic_events.empty? || part.spans.any?(&:hairpin?)
    end

    # A part's own dynamics are written in a \new Dynamics, so only the voice's
    # are placed among its links. A nil voice is a staff nobody is written on.
    def timed_marks(voice)
      @timed_marks ||= {}.compare_by_identity
      @timed_marks[voice] ||= voice ? TimedMarks.voice(voice, lead: lead?(voice)) : TimedMarks.new([])
    end

    # The flow's tempo marks are written in its first voice.
    def lead?(voice)
      voice.equal?(flow.voices.first)
    end

    # The voice events marked with each fermata they sound under where it
    # begins.
    def fermata_carriers
      @fermata_carriers ||= HeadMusic::Notation::FermataMarks.carriers(flow)
    end

    # What ends a hairpin on the final barline, after the owner's last link or
    # spacer: \after there prints "no broken bound" for a level, and a marker
    # with no duration reaches it cleanly. The first voice then writes the
    # tempo marks there, as a ramp's target.
    def final_barline_marks(owner)
      final_barline = flow.final_barline_position
      hairpin_end = "<>\\!" if owner&.spans&.any? { |span| span.hairpin? && span.to == final_barline }
      marks = [hairpin_end, *(final_tempo_marks if owner && lead?(owner))].compact
      marks.join(" ") unless marks.empty?
    end

    def bar_length(bar_number)
      return short_final_bar_fraction if bar_number == bar_numbers.last && short_final_bar_fraction

      meter = effective_meter(bar_number)
      Rational(meter.top_number, meter.bottom_number)
    end

    private

    def precompute_eager_data
      super
      tokens_by_segment
      flow.parts.each { |part| dynamics_bars(part) if dynamics?(part) }
      [nil, *flow.voices].each { |voice| trailing_spacers(voice) } if trailing_marks?
    end

    # A part's levels and hairpins, which its \new Dynamics holds apart from
    # its voices, so a voice's level does not cut a part's hairpin.
    def part_marks(part)
      @part_marks ||= {}.compare_by_identity
      @part_marks[part] ||= TimedMarks.part(part)
    end

    def music_end
      return @music_end if defined?(@music_end)

      @music_end = flow.voices.filter_map { |voice| voice.last_voice_event&.next_position }.max
    end

    def trailing_marks?
      return @trailing_marks if defined?(@trailing_marks)

      owners_marks = flow.parts.map { |part| part_marks(part) } + flow.voices.map { |voice| timed_marks(voice) }
      @trailing_marks = !music_end_fraction.nil? && owners_marks.any? { |marks| marks.trailing(bar_numbers.last, music_end_fraction).any? }
    end

    # LilyPond has no way to say "three flats read as dorian", so it renders
    # what is printed at the clef.
    def key_value(event)
      KeyMapper.token(event.printed_key_signature)
    end

    def segment_tokens(voice)
      @segment_tokens ||= {}.compare_by_identity
      @segment_tokens[voice] ||= SegmentTokens.new(voice, segments_by_bar(voice).values.flatten, timed_marks(voice), fermata_carriers)
    end

    def final_tempo_marks
      final_barline = flow.final_barline_position
      HeadMusic::Notation::TempoMarks.new(flow).select { |mark| mark.position == final_barline }.filter_map do |mark|
        token, rank = TimedMarks.tempo_token(mark)
        (rank == TimedMarks::BEFORE_RANK) ? token : token && "<>#{token}"
      end
    end
  end
end
