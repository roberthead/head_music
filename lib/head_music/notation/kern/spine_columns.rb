# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # The columns of a written kern file, and the rows laid across them: one
  # **kern spine per voice, a **text spine beside each sung voice for each
  # verse, and a **dynam spine after the rightmost spine of each part with
  # dynamics.
  #
  # Parts, and the staves within a part, run bottom to top from the left,
  # so the bass is the leftmost spine; within one staff the voices run left
  # to right upper first, which is how the reader gives them back.
  class SpineColumns
    include Enumerable

    # A **dynam column's voice is the one whose spine it follows.
    Column = Data.define(:voice, :verse, :part_number, :staff, :dynam) do
      def initialize(dynam: false, **fields)
        super
      end

      def kern?
        verse.nil? && !dynam
      end

      def exclusive
        return "**dynam" if dynam

        kern? ? "**kern" : "**text"
      end
    end

    # Voices sit on the staff they start on, in +bar_number+. A part gets a
    # **dynam spine when its entry in +dynamic_fields+ holds anything.
    def initialize(flow, bar_number, dynamic_fields)
      @flow = flow
      @bar_number = bar_number
      @dynamic_fields = dynamic_fields
    end

    def each(&block)
      columns.each(&block)
    end

    def row(&block)
      map(&block).join("\t")
    end

    def uniform_row(field)
      row { field }
    end

    # Kern fields for kern columns, and a null interpretation beside them.
    def kern_row(&block)
      row { |column| column.kern? ? block.call(column) : "*" }
    end

    def kern_row_unless_null(&block)
      fields = map { |column| column.kern? ? block.call(column) || "*" : "*" }
      fields.join("\t") unless fields.all?("*")
    end

    private

    attr_reader :flow

    def columns
      @columns ||= flow.parts.reverse.flat_map { |part| part_columns(part) }
    end

    def part_columns(part)
      columns = part.staff_system.staves.reverse.flat_map { |staff| staff_columns(part, staff) }
      @dynamic_fields.fetch(part).empty? ? columns : [*columns, columns.last.with(verse: nil, dynam: true)]
    end

    def staff_columns(part, staff)
      part.voices.select { |voice| voice.staff_at(@bar_number).equal?(staff) }.flat_map do |voice|
        kern = Column.new(voice: voice, verse: nil, part_number: flow.parts.index(part) + 1, staff: staff)
        [kern, *verses(voice).map { |verse| kern.with(verse: verse) }]
      end
    end

    def verses(voice)
      last_verse = voice.voice_events.flat_map { |voice_event| voice_event.syllables.keys }.max
      last_verse ? (1..last_verse).to_a : []
    end
  end
end
