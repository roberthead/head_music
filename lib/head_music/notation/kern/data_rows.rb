# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # A bar's data rows: one wherever a voice attacks or a dynamic falls,
  # holding each column's token, syllable, or dynamic.
  class DataRows
    def initialize(columns, bars, dynamic_fields)
      @columns = columns
      @bars = bars
      @dynamic_fields = dynamic_fields
    end

    def in_bar(bar_number)
      events = kern_events(bar_number)
      attacks = events.values.flatten.map { |event| Rational(event.offset) }
      dynamics = dynamic_offsets(bar_number)
      cut_for_dynamics(events, dynamics, attacks)
      (attacks + dynamics.values.flatten).uniq.sort.map do |offset|
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
      dynamic_fields.transform_values do |fields|
        offsets = fields.in_bar(bar_number).keys.map { |offset| Rational(offset) }
        offsets.select { |offset| offset < bars.length(bar_number) }
      end
    end

    # A dynamic where nothing attacks splits its part's notes there.
    def cut_for_dynamics(events, dynamics, attacks)
      dynamics.each do |part, offsets|
        cuts = offsets - attacks
        part.voices.each { |voice| events[voice] = SpineTokens.cut(events.fetch(voice), cuts) } if cuts.any?
      end
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
