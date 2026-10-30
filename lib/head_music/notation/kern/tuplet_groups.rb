# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Kern writes no tuplet brackets, so a voice's groups are inferred from its
  # values, link by link, since a tied chain may mix ratios. A group starts
  # at a link of a ratio, gathers the consecutive links of exactly that ratio
  # after it, rests and tied chains included, and closes at the first point
  # where links of at least two voice events sum to a plain undotted note
  # value. A run that never fills stays ungrouped.
  #
  # Barlines do not end a group, since a piece split at one reads back as a
  # chain of the same ratio. A sextuplet comes back as two triplets.
  module TupletGroups
    # One link: its ratio, its exact fraction of a whole note, and which
    # voice event it belongs to.
    Item = Data.define(:ratio, :fraction, :event)

    module_function

    # Groups the voice's inferred runs, leaving one ungrouped where the
    # voice refuses it, as where a rounding ratio's leftover comes first.
    def apply(voice)
      links = voice.voice_events.flat_map { |voice_event| HeadMusic::Content::TupletGroup.links_of(voice_event) }
      items = links.map { |link| Item.new(link.ratio, link.rhythmic_value.link_fraction, link.voice_event) }
      runs(items).each do |run|
        voice.group_tuplet(from: links[run.first].start_position, to: links[run.last].end_position)
      rescue ArgumentError
        nil
      end
    end

    # The items of a duration's values, as one voice event.
    def items_of(rhythmic_duration, event)
      rhythmic_duration.values.map { |link| Item.new(link.tuplet_ratio, link.link_fraction, event) }
    end

    # The index ranges of the items each group holds.
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
      return unless ratio && edge?(items, start - 1, start)

      total = 0
      rounds = false
      (start...items.length).each do |index|
        break unless items[index].ratio == ratio

        total += items[index].fraction
        rounds ||= rounds?(items[index])
        return index if closes?(items, start, index, total, rounds)
      end
      nil
    end

    # A group ends at a plain length, with links of two voice events, and
    # never between two links of one chain of its ratio, which are the
    # pieces of a note split at a barline. A ratio that rounds must start and
    # end where voice events do.
    def closes?(items, start, index, total, rounds)
      return false if items[index].event.equal?(items[start].event) || !plain?(total)
      return false unless edge?(items, index, index + 1)

      !rounds || (event_edge?(items, start - 1, start) && event_edge?(items, index, index + 1))
    end

    # Whether a group may meet the item after: between voice events, or
    # where a chain changes ratio.
    def edge?(items, before, after)
      event_edge?(items, before, after) || items[before].ratio != items[after].ratio
    end

    def event_edge?(items, before, after)
      before.negative? || after >= items.length || !items[before].event.equal?(items[after].event)
    end

    def rounds?(item)
      (item.fraction * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE).denominator != 1
    end

    def plain?(fraction)
      [fraction.numerator, fraction.denominator].all? { |integer| HeadMusic::Notation::DottedDuration.power_of_two?(integer) }
    end
  end
end
