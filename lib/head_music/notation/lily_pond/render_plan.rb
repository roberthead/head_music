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

    # The length, as a fraction of a whole note, of a final bar that every
    # voice ends short of together, or nil where the final bar is full.
    def short_final_bar_fraction
      return @short_final_bar_fraction if defined?(@short_final_bar_fraction)

      finish = flow.voices.filter_map { |voice| voice.last_placement&.next_position }.max
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

    # A tied chain within a placement joins its links with the tie mark, and
    # so does a placement split at a barline, whose piece before the bar check
    # ends in one; a chain of rests emits consecutive untied rests, and a tied
    # chord repeats the whole chord.
    def token(segment)
      placement = segment.placement
      links = segment.rhythmic_value!(RenderError).tied_chain
      return links.map { |link| "r#{DurationWriter.token(link)}" }.join(" ") if placement.rest?

      body = placement.chord? ? chord_body(placement) : PitchWriter.token(placement.pitch)
      tokens = links.map { |link| "#{body}#{DurationWriter.token(link)}" }.join("~ ")
      segment.continues ? "#{tokens}~" : tokens
    end

    def chord_body(placement)
      "<#{placement.pitches.sort.map { |pitch| PitchWriter.token(pitch) }.join(" ")}>"
    end
  end
end
