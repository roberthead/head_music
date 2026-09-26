# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # What a part's **dynam spine holds, by bar and offset: its own levels,
  # its voices' levels, and the accents a kern token cannot carry.
  #
  # The spine holds one value per row and cannot say which voice it means,
  # so where several fall at one position it keeps the first of the part's
  # level, each voice's level in voice order, and each voice's accent.
  class DynamicFields
    # sfz is written in the token, as z.
    SPINE_ACCENTS = %w[sf rfz fp].freeze

    # A dynamic before a pickup's first note moves to that note, since kern
    # starts the pickup there.
    def initialize(part, pickup_bar:, pickup_start:)
      @part = part
      @pickup_bar = pickup_bar
      @pickup_start = pickup_start
    end

    def empty?
      by_bar.empty?
    end

    # The offsets in the bar that carry a dynamic, each with its key.
    def in_bar(bar_number)
      by_bar.fetch(bar_number, {})
    end

    private

    attr_reader :part

    def by_bar
      @by_bar ||= candidates.each_with_object({}) do |(position, dynamic), fields|
        bar_fields = fields[position.bar_number] ||= {}
        bar_fields[offset(position)] ||= dynamic.name_key
      end
    end

    def candidates
      [
        *level_positions(part),
        *part.voices.flat_map { |voice| level_positions(voice) },
        *part.voices.flat_map { |voice| accent_positions(voice) }
      ]
    end

    def level_positions(owner)
      owner.dynamic_events.map { |dynamic_event| [dynamic_event.position, dynamic_event.level] }
    end

    def accent_positions(voice)
      voice.note_events.filter_map do |note_event|
        [note_event.position, note_event.note_dynamic] if SPINE_ACCENTS.include?(note_event.note_dynamic&.name_key)
      end
    end

    def offset(position)
      offset = HeadMusic::Notation::BarSplitter.offset_in_bar(position)
      return offset unless position.bar_number == @pickup_bar && @pickup_start

      Rational([offset, @pickup_start].max)
    end
  end
end
