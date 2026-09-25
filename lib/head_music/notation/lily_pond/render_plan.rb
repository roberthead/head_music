# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # The computed musical facts a Writer needs to serialize a flow:
  # the tokens for every placement in each bar it sounds in, on top of the measure signatures the base
  # plan tracks. Construction eagerly computes everything that can raise
  # on unmappable keys, durations, or alterations, so a RenderPlan that builds successfully
  # cannot fail assembly on those grounds.
  class RenderPlan < HeadMusic::Notation::RenderPlan
    def tokens_by_segment
      @tokens_by_segment ||= flow.voices.flat_map { |voice| segments_by_bar(voice).values.flatten }.to_h do |segment|
        [segment, token(segment)]
      end
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

    # A tied chain within a placement joins its links with the tie mark, and
    # so does a placement split at a barline, whose piece before the bar check
    # ends in one; a chain of rests emits consecutive untied rests, and a tied
    # chord repeats the whole chord.
    def token(segment)
      placement = segment.placement
      links = segment_rhythmic_value(segment).tied_chain
      return links.map { |link| "r#{DurationWriter.token(link)}" }.join(" ") if placement.rest?

      body = placement.chord? ? chord_body(placement) : PitchWriter.token(placement.pitch)
      tokens = links.map { |link| "#{body}#{DurationWriter.token(link)}" }.join("~ ")
      segment.continues ? "#{tokens}~" : tokens
    end

    def chord_body(placement)
      "<#{placement.pitches.sort.map { |pitch| PitchWriter.token(pitch) }.join(" ")}>"
    end

    def segment_rhythmic_value(segment)
      segment.rhythmic_value || raise(
        RenderError,
        "cannot express the part of the note at #{segment.placement.position} in bar #{segment.bar_number} " \
        "in binary note values"
      )
    end
  end
end
