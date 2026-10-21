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
        section_row(first_bar),
        columns.kern_row_unless_null { |column| ClefCodes.clef_field(opening_clef(column.staff)) },
        *context_rows(plan.first_measure_key, plan.first_measure_meter, opening_tempo_fields)
      ].compact
    end

    def changes(bar_number)
      return [] unless bar_number > first_bar

      [
        section_row(bar_number),
        columns.kern_row_unless_null { |column| staff_change(column, bar_number) },
        columns.kern_row_unless_null { |column| clef_change(column, bar_number) },
        *context_rows(plan.measure_key_changes[bar_number], plan.measure_time_changes[bar_number], tempo_change_fields(bar_number))
      ].compact
    end

    private

    attr_reader :flow, :plan, :columns

    def first_bar
      plan.bar_numbers.first
    end

    # A section label runs to the end of its field, so whitespace that would
    # split the row becomes a space, and brackets, which would make it an
    # expansion list, become parentheses.
    def section_row(bar_number)
      mark = plan.bar(bar_number)&.rehearsal_mark
      mark && columns.uniform_row("*>#{mark.gsub(/\s+/, " ").tr("[]", "()")}")
    end

    def context_rows(key, meter, tempo_fields)
      [key&.signature, key&.designation, *meter_fields(meter), *tempo_fields]
        .map { |field| columns.kern_row_unless_null { field } }
    end

    def meter_fields(meter)
      meter ? [MeterReader.meter_field(meter), MeterReader.symbol_field(meter)] : []
    end

    # The opening tempo's words are its !!!OMD record, so only its number,
    # if it was written, is an interpretation.
    def opening_tempo_fields
      tempo = flow.tempo_at(first_bar)
      (tempo.metronome_mark? || tempo.text.nil?) ? [TempoReader.tempo_field(tempo)] : []
    end

    # Kern has no ramps, so a bar is written with the tempo authored for it,
    # wherever a ramp or "a tempo" changed it.
    def tempo_change_fields(bar_number)
      tempo = flow.tempo_at(bar_number)
      (tempo == flow.tempo_at(bar_number - 1)) ? [] : TempoReader.tempo_fields(tempo)
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
      @staves ||= flow.parts.flat_map { |part| part.staff_system.staves }
      @staves.index { |each_staff| each_staff.equal?(staff) } + 1
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
