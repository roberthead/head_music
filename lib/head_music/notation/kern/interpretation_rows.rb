# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # The interpretation rows that set up the spines before the first bar,
  # and those that change them at the start of a later one.
  class InterpretationRows
    def initialize(flow, plan, columns)
      @flow = flow
      @plan = plan
      @columns = columns
    end

    def opening
      [
        *grouping_rows,
        columns.kern_row_unless_null { |column| InstrumentCodes.code_field(column.voice.part.instrument) },
        columns.kern_row_unless_null { |column| player_name(column) },
        columns.kern_row_unless_null { |column| ClefCodes.clef_field(opening_clef(column.staff)) },
        *context_rows(plan.first_measure_key, plan.first_measure_meter, flow.tempo_at(first_bar))
      ].compact
    end

    def changes(bar_number)
      return [] unless bar_number > first_bar

      [
        columns.kern_row_unless_null { |column| staff_change(column, bar_number) },
        columns.kern_row_unless_null { |column| clef_change(column, bar_number) },
        *context_rows(plan.measure_key_changes[bar_number], plan.measure_time_changes[bar_number], flow.tempo_changes[bar_number])
      ].compact
    end

    private

    attr_reader :flow, :plan, :columns

    def first_bar
      plan.bar_numbers.first
    end

    def context_rows(key, meter, tempo)
      [
        key && columns.kern_row { key.signature },
        key && columns.kern_row_unless_null { key.designation },
        meter && columns.kern_row { MeterReader.meter_field(meter) },
        tempo && columns.kern_row { TempoReader.tempo_field(tempo) }
      ]
    end

    def player_name(column)
      name = column.voice.part.player&.name
      name && InstrumentCodes.name_field(name)
    end

    def grouping_rows
      return [] unless grouped?

      [
        columns.kern_row { |column| "*part#{column.part_number}" },
        columns.kern_row { |column| "*staff#{staff_number(column.staff)}" }
      ]
    end

    def grouped?
      flow.parts.any? { |part| part.voices.length > 1 || part.staff_system.length > 1 }
    end

    # Numbered down the whole score, as Humdrum numbers staves.
    def staff_number(staff)
      @staff_numbers ||= flow.parts.flat_map { |part| part.staff_system.staves }.each_with_index.to_h do |each_staff, index|
        [each_staff.object_id, index + 1]
      end
      @staff_numbers.fetch(staff.object_id)
    end

    # An unauthored clef falls back to the one the other writers infer,
    # chosen once per staff so that every voice on it agrees.
    def opening_clef(staff)
      staff.clef_at(first_bar) || fallback_clefs[staff.object_id]
    end

    def fallback_clefs
      @fallback_clefs ||= columns.select(&:kern?).each_with_object({}) do |column, clefs|
        clefs[column.staff.object_id] ||= HeadMusic::Notation::ClefSelector.for(column.voice)
      end
    end

    def clef_change(column, bar_number)
      clef = column.voice.staff_at(bar_number).clef_changes[bar_number]
      clef && ClefCodes.clef_field(clef)
    end

    def staff_change(column, bar_number)
      staff = column.voice.staff_at(bar_number)
      "*staff#{staff_number(staff)}" unless staff.equal?(column.voice.staff_at(bar_number - 1))
    end
  end
end
