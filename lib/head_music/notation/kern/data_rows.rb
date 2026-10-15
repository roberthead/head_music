# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # A bar's data rows: one wherever a voice attacks or a dynamic falls,
  # holding each column's token, syllable, or dynamic.
  #
  # A row has a time of its own only where something attacks. Rows between
  # two such rows split the time between them evenly, so a dynamic where
  # nothing attacks goes on one of a run of null rows spaced to land on it.
  class DataRows
    def initialize(columns, bars, dynamic_fields)
      @columns = columns
      @bars = bars
      @dynamic_fields = dynamic_fields
    end

    def in_bar(bar_number)
      events = kern_events(bar_number)
      attacks = events.values.flatten.map { |event| Rational(event.offset) }.uniq.sort
      offsets = row_offsets(attacks, dynamic_offsets(bar_number), bars.length(bar_number))
      offsets = with_final_close_row(bar_number, attacks, offsets) if final_closes?(bar_number)
      offsets.flat_map do |offset|
        main = columns.row do |column|
          text = field(column, events, bar_number, offset)
          (column.dynam && final_closes?(bar_number) && offset == offsets.last) ? final_field(column, text) : text
        end
        [*grace_rows(events, offset), main]
      end
    end

    private

    # The grace notes before the notes at an offset, on rows of their own
    # just before them, each spine's last one on the last row.
    def grace_rows(events, offset)
      graces = events.transform_values { |voice_events| voice_events.find { |event| event.offset == offset }&.graces || [] }
      count = graces.values.map(&:length).max || 0
      (0...count).map do |row|
        columns.row do |column|
          tokens = column.kern? ? graces.fetch(column.voice) : []
          index = row - (count - tokens.length)
          index.negative? ? "." : tokens[index]
        end
      end
    end

    attr_reader :columns, :bars, :dynamic_fields

    def final_closes?(bar_number)
      bar_number == bars.numbers.last && dynamic_fields.values.any?(&:final_close)
    end

    # A doubled close ends where its row ends, so one on the bar's last row
    # ends on the final barline. A row that opens that same hairpin would
    # read as a hairpin to the next row with the close beside it, so the
    # close goes on one more null row after it.
    def with_final_close_row(bar_number, attacks, offsets)
      last = offsets.last
      return offsets unless opens_final_hairpin?(bar_number, last)

      length = bars.length(bar_number)
      row_offsets(attacks, dynamic_offsets(bar_number) + [(last + length) / 2], length)
    end

    def opens_final_hairpin?(bar_number, offset)
      dynamic_fields.values.filter_map(&:final_hairpin).any? do |hairpin|
        hairpin.from.bar_number == bar_number && MarkOffset.in_bar(hairpin.from) == offset
      end
    end

    def final_field(column, text)
      close = dynamic_fields.fetch(column.voice.part).final_close
      return text unless close

      (text == ".") ? close : "#{text}#{close}"
    end

    def kern_events(bar_number)
      columns.select(&:kern?).to_h { |column| [column.voice, bars.events(column.voice, bar_number)] }
    end

    def dynamic_offsets(bar_number)
      dynamic_fields.values.flat_map { |fields| fields.in_bar(bar_number).keys.map { |offset| Rational(offset) } }.uniq
    end

    def row_offsets(attacks, dynamics, length)
      untimed = (attacks + [length]).each_cons(2).flat_map { |from, to| untimed_offsets(from, to, dynamics) }
      (attacks + untimed).sort
    end

    # The null rows between two timed rows: the fewest evenly spaced ones
    # that land on every dynamic between them.
    def untimed_offsets(from, to, dynamics)
      inside = dynamics.select { |offset| offset > from && offset < to }
      return [] if inside.empty?

      step = inside.map { |offset| offset - from }.reduce(to - from) { |gcd, span| rational_gcd(gcd, span) }
      (1...((to - from) / step)).map { |index| from + step * index }
    end

    def rational_gcd(one, other)
      Rational(one.numerator.gcd(other.numerator), one.denominator.lcm(other.denominator))
    end

    def field(column, all_events, bar_number, offset)
      return dynamic_fields.fetch(column.voice.part).in_bar(bar_number).fetch(offset, ".") if column.dynam

      event = all_events.fetch(column.voice).find { |candidate| candidate.offset == offset }
      return "." unless event

      column.kern? ? event.token : syllable_field(column, event)
    end

    def syllable_field(column, event)
      syllable = event.syllables[column.verse]
      return "." unless syllable

      key = [column.voice.object_id, column.verse]
      continued = hyphens[key]
      hyphens[key] = syllable.hyphen_after?
      "#{"-" if continued}#{syllable.text}#{"-" if syllable.hyphen_after?}"
    end

    def hyphens
      @hyphens ||= {}
    end
  end
end
