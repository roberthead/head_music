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
      attacks = events.values.flatten.map { |event| Rational(event.offset) }.uniq.sort
      offsets = RowOffsets.for(attacks, dynamic_offsets(bar_number), bars.length(bar_number))
      final = final_closes?(bar_number)
      offsets = with_final_close_row(bar_number, attacks, offsets) if final
      last = offsets.last
      offsets.flat_map do |offset|
        at = events.transform_values { |voice_events| voice_events.find { |event| event.offset == offset } }
        closing = final && offset == last
        main = columns.row do |column|
          column.dynam ? dynamic_field(column, bar_number, offset, closing) : field(column, at.fetch(column.voice))
        end
        [*grace_rows(at), main]
      end
    end

    private

    # The grace notes before the notes at an offset, on rows of their own
    # just before them, each spine's last one on the last row.
    def grace_rows(at)
      graces = at.transform_values { |event| event&.graces || [] }
      count = graces.values.map(&:length).max || 0
      padded = graces.transform_values { |tokens| Array.new(count - tokens.length, ".") + tokens }
      (0...count).map { |row| columns.row { |column| column.kern? ? padded.fetch(column.voice)[row] : "." } }
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
      RowOffsets.for(attacks, dynamic_offsets(bar_number) + [(last + length) / 2], length)
    end

    def opens_final_hairpin?(bar_number, offset)
      dynamic_fields.values.filter_map(&:final_hairpin).any? do |hairpin|
        hairpin.from.bar_number == bar_number && MarkOffset.in_bar(hairpin.from) == offset
      end
    end

    def dynamic_field(column, bar_number, offset, closing)
      fields = dynamic_fields.fetch(column.voice.part)
      text = fields.in_bar(bar_number).fetch(offset, ".")
      close = fields.final_close if closing
      return text unless close

      (text == ".") ? close : "#{text}#{close}"
    end

    def kern_events(bar_number)
      columns.select(&:kern?).to_h { |column| [column.voice, bars.events(column.voice, bar_number)] }
    end

    def dynamic_offsets(bar_number)
      dynamic_fields.values.flat_map { |fields| fields.in_bar(bar_number).keys }.map { |offset| Rational(offset) }.uniq
    end

    def field(column, event)
      return "." unless event

      column.kern? ? event.token : syllable_field(column, event)
    end

    def syllable_field(column, event)
      syllable = event.syllables[column.verse]
      return "." unless syllable

      key = [column.voice.object_id, column.verse]
      continued = hyphens[key]
      hyphens[key] = syllable.hyphen_after?
      "#{"-" if continued}#{syllable.text}#{"-" if syllable.hyphen_after?}#{"_" if event.extended.include?(column.verse)}"
    end

    def hyphens
      @hyphens ||= {}
    end
  end
end
