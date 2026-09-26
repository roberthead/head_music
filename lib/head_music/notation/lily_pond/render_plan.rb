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
    # voice ends short of together, or nil where the final bar is full.
    def short_final_bar_fraction
      return @short_final_bar_fraction if defined?(@short_final_bar_fraction)

      finish = flow.voices.filter_map { |voice| voice.last_voice_event&.next_position }.max
      offset = finish && HeadMusic::Notation::BarSplitter.offset_in_bar(finish)
      @short_final_bar_fraction = (offset && !offset.zero?) ? offset : nil
    end

    private

    def precompute_eager_data
      super
      tokens_by_segment
    end

    # LilyPond has no way to say "three flats read as dorian", so it renders
    # what is printed at the clef.
    def key_value(event)
      KeyMapper.token(event.printed_key_signature)
    end

    # A tied chain within a voice event joins its links with the tie mark, and
    # so does a voice event split at a barline, whose piece before the bar check
    # ends in one; a chain of rests emits consecutive untied rests, and a tied
    # chord repeats the whole chord. Only the first link carries the marks.
    def token(segment)
      voice_event = segment.voice_event
      first, *later = segment.rhythmic_value!(RenderError).tied_chain.map do |link|
        "#{body(voice_event)}#{DurationWriter.token(link)}"
      end
      words = ["#{first}#{marks(segment)}", *later]
      return words.join(" ") if voice_event.rest?

      tokens = words.join("~ ")
      segment.continues ? "#{tokens}~" : tokens
    end

    def body(voice_event)
      return "r" if voice_event.rest?

      voice_event.chord? ? chord_body(voice_event) : PitchWriter.token(voice_event.pitch)
    end

    # A voice event split at a barline is marked where it starts.
    def marks(segment)
      voice_event = segment.voice_event
      return "" unless segment.bar_number == voice_event.position.bar_number

      MarkWriter.token(voice_event, dynamic_placement(voice_event.voice).level_for(voice_event))
    end

    # A part's own dynamics are written in a \new Dynamics, so only the voice's
    # are placed on its notes.
    def dynamic_placement(voice)
      @dynamic_placements ||= {}.compare_by_identity
      @dynamic_placements[voice] ||= HeadMusic::Notation::DynamicPlacement.new(voice)
    end

    def chord_body(voice_event)
      "<#{voice_event.pitches.sort.map { |pitch| PitchWriter.token(pitch) }.join(" ")}>"
    end
  end
end
