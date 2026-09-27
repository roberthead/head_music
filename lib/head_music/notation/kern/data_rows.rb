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
      row_offsets(attacks, dynamic_offsets(bar_number), bars.length(bar_number)).map do |offset|
        columns.row { |column| field(column, events, bar_number, offset) }
      end
    end

    private

    attr_reader :columns, :bars, :dynamic_fields

    def kern_events(bar_number)
      columns.select(&:kern?).to_h { |column| [column.voice, bars.events(column.voice, bar_number)] }
    end

    # A dynamic after the flow's last note has no row to go on.
    def dynamic_offsets(bar_number)
      offsets = dynamic_fields.values.flat_map { |fields| fields.in_bar(bar_number).keys.map { |offset| Rational(offset) } }
      offsets.uniq.select { |offset| offset < bars.length(bar_number) }
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
