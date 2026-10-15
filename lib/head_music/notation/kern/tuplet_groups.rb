# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Kern writes no tuplet brackets, so a voice's groups are inferred from its
  # values. A group starts at a value of a ratio, gathers the consecutive
  # values of exactly that ratio after it, rests and tied chains included,
  # and closes at the first point where at least two of them sum to a plain
  # undotted note value. A run that never fills stays ungrouped.
  #
  # Barlines do not end a group, since a piece split at one reads back as a
  # chain of the same ratio. A sextuplet comes back as two triplets.
  module TupletGroups
    Item = Data.define(:ratio, :fraction)

    module_function

    # Groups the voice's inferred runs, leaving one ungrouped where the
    # voice refuses it, as where a rounding ratio's leftover comes first.
    def apply(voice)
      events = voice.voice_events
      runs(events.map { |voice_event| item(voice_event.rhythmic_value) }).each do |run|
        voice.group_tuplet(from: events[run.first].position, to: events[run.last].next_position)
      rescue ArgumentError
        nil
      end
    end

    def item(rhythmic_value)
      Item.new(rhythmic_value.uniform_tuplet_ratio, rhythmic_value.fraction)
    end

    # The index ranges of the items each group holds. Each item answers its
    # ratio, or nil, and its exact fraction of a whole note.
    def runs(items)
      runs = []
      start = 0
      while start < items.length
        last = closing_index(items, start)
        runs << (start..last) if last
        start = last ? last + 1 : start + 1
      end
      runs
    end

    def closing_index(items, start)
      ratio = items[start].ratio
      return unless ratio

      total = 0
      (start...items.length).each do |index|
        break unless items[index].ratio == ratio

        total += items[index].fraction
        return index if index > start && plain?(total)
      end
      nil
    end

    def plain?(fraction)
      power_of_two?(fraction.numerator) && power_of_two?(fraction.denominator)
    end

    def power_of_two?(integer)
      (integer & (integer - 1)).zero?
    end
  end
end
