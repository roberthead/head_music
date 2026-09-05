# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # The computed musical facts a Writer needs to serialize a composition:
  # the token for every placement, on top of the measure signatures the base
  # plan tracks. Construction eagerly computes everything that can raise
  # on unmappable keys, durations, or alterations, so a RenderPlan that builds successfully
  # cannot fail assembly on those grounds.
  class RenderPlan < HeadMusic::Notation::RenderPlan
    def tokens_by_placement
      @tokens_by_placement ||= composition.voices.flat_map(&:placements).to_h do |placement|
        [placement, token(placement)]
      end
    end

    private

    def precompute_eager_data
      super
      tokens_by_placement
    end

    def key_value(key_signature)
      KeyMapper.token(key_signature)
    end

    # A tied chain within a placement joins its links with the tie mark;
    # a chain of rests emits consecutive untied rests, and a tied chord
    # repeats the whole chord.
    def token(placement)
      return rest_token(placement) if placement.rest?
      return chord_token(placement) if placement.chord?

      note_token(placement)
    end

    def rest_token(placement)
      placement.rhythmic_value.tied_chain.map { |link| "r#{DurationWriter.token(link)}" }.join(" ")
    end

    def note_token(placement)
      pitch_token = PitchWriter.token(placement.pitch)
      placement.rhythmic_value.tied_chain.map { |link| "#{pitch_token}#{DurationWriter.token(link)}" }.join("~ ")
    end

    def chord_token(placement)
      body = "<#{placement.pitches.sort.map { |pitch| PitchWriter.token(pitch) }.join(" ")}>"
      placement.rhythmic_value.tied_chain.map { |link| "#{body}#{DurationWriter.token(link)}" }.join("~ ")
    end
  end
end
