# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # The computed musical facts a Writer needs to serialize a composition:
  # the token for every placement and the key/time signatures in force at
  # each measure. Construction eagerly computes everything that can raise
  # on unmappable keys, durations, or alterations, so a RenderPlan that builds successfully
  # cannot fail assembly on those grounds.
  class RenderPlan
    attr_reader :composition

    def initialize(composition)
      @composition = composition
      precompute_eager_data
    end

    def bar_numbers
      composition.earliest_bar_number..composition.latest_bar_number
    end

    def measure_key_changes
      @measure_key_changes ||= bar_numbers.zip(composition.bars).filter_map { |bar_number, bar|
        [bar_number, KeyMapper.token(bar.key_signature)] if bar.key_signature
      }.to_h
    end

    def measure_time_changes
      @measure_time_changes ||= bar_numbers.zip(composition.bars).filter_map { |bar_number, bar|
        [bar_number, bar.meter] if bar.meter
      }.to_h
    end

    def first_measure_key
      @first_measure_key ||=
        measure_key_changes[bar_numbers.first] || KeyMapper.token(composition.key_signature)
    end

    def first_measure_meter
      @first_measure_meter ||= effective_meter(bar_numbers.first)
    end

    def effective_meter(bar_number)
      change_bar = measure_time_changes.keys.select { |number| number <= bar_number }.max
      change_bar ? measure_time_changes[change_bar] : composition.meter
    end

    def placements_by_bar(voice)
      @placements_by_bar ||= {}
      @placements_by_bar[voice] ||= voice.placements.group_by { |placement| placement.position.bar_number }
    end

    def tokens_by_placement
      @tokens_by_placement ||= composition.voices.flat_map(&:placements).to_h do |placement|
        [placement, token(placement)]
      end
    end

    private

    # Everything that can raise on unmappable keys, durations, or
    # alterations is computed here so it raises at construction, before the
    # Writer assembles output.
    def precompute_eager_data
      first_measure_key
      first_measure_meter
      measure_key_changes
      measure_time_changes
      tokens_by_placement
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
