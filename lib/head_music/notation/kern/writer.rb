# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # Assembles a **kern document from a flow: its reference records, the
  # spines' exclusive interpretations and the interpretations that set them
  # up, then each bar's barline, interpretation changes, and data rows.
  #
  # A spine never splits: every voice is written from the flow's first bar
  # to its end, with rests wherever it is silent.
  class Writer
    attr_reader :flow

    def initialize(flow, transposed: false)
      @flow = flow
      @transposed = transposed
    end

    def to_s
      Preflight.check!(flow, transposed: @transposed)
      lines = [
        *ReferenceRecords.lines(flow),
        columns.row(&:exclusive),
        *interpretations.opening,
        *body_rows,
        columns.uniform_row(bars.final_barline),
        columns.uniform_row("*-")
      ]
      "#{lines.join("\n")}\n"
    end

    private

    def body_rows
      bars.numbers.flat_map do |bar_number|
        barline = bars.barline(bar_number)
        [
          barline && columns.uniform_row(barline),
          *interpretations.changes(bar_number),
          *data_rows.in_bar(bar_number)
        ].compact
      end
    end

    def plan
      @plan ||= RenderPlan.new(flow)
    end

    def bars
      @bars ||= WrittenBars.new(flow, plan)
    end

    def dynamic_fields
      @dynamic_fields ||= flow.parts.to_h do |part|
        [part, DynamicFields.new(part, pickup_bar: WrittenBars::PICKUP_BAR, pickup_start: bars.pickup_start)]
      end
    end

    def columns
      @columns ||= SpineColumns.new(flow, bars.first, dynamic_fields)
    end

    def interpretations
      @interpretations ||= InterpretationRows.new(flow, plan, columns)
    end

    def data_rows
      @data_rows ||= DataRows.new(columns, bars, dynamic_fields)
    end
  end
end
