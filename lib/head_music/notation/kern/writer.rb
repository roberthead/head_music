# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # Assembles a **kern document from a flow: one spine per voice, and a
  # **text spine beside each sung voice for each verse.
  #
  # Parts, and the staves within a part, run bottom to top from the left,
  # so the bass is the leftmost spine; within one staff the voices run left
  # to right upper first, which is how the reader gives them back. A spine
  # never splits: every voice is written from the flow's first bar to its
  # end, with rests wherever it is silent. A pickup bar's leading silence is
  # left out, since kern starts a pickup at its first note.
  class Writer
    Column = Data.define(:voice, :verse, :part_number, :staff) do
      def kern?
        verse.nil?
      end
    end

    PICKUP_BAR = 0

    attr_reader :flow

    def initialize(flow, transposed: false)
      @flow = flow
      @transposed = transposed
    end

    def to_s
      Preflight.check!(flow, transposed: @transposed)
      lines = [*reference_records, row(columns.map { |column| column.kern? ? "**kern" : "**text" })]
      lines.concat(header_rows)
      lines.concat(body_rows)
      lines << row(fields_for_all("==#{final_style}"))
      lines << row(fields_for_all("*-"))
      "#{lines.join("\n")}\n"
    end

    private

    def plan
      @plan ||= RenderPlan.new(flow)
    end

    def columns
      @columns ||= flow.parts.reverse.flat_map do |part|
        part.staff_system.staves.reverse.flat_map do |staff|
          part.voices.select { |voice| voice.staff_at(first_bar).equal?(staff) }.flat_map do |voice|
            kern = Column.new(voice: voice, verse: nil, part_number: flow.parts.index(part) + 1, staff: staff)
            [kern, *verses(voice).map { |verse| kern.with(verse: verse) }]
          end
        end
      end
    end

    def verses(voice)
      last_verse = voice.placements.flat_map { |placement| placement.syllables.keys }.max
      last_verse ? (1..last_verse).to_a : []
    end

    def row(fields)
      fields.join("\t")
    end

    def fields_for_all(field)
      columns.map { field }
    end

    # Kern fields for kern columns, and a null interpretation beside them.
    def kern_row(&block)
      row(columns.map { |column| column.kern? ? block.call(column) : "*" })
    end

    def kern_row_unless_null(&block)
      fields = columns.map { |column| column.kern? ? block.call(column) || "*" : "*" }
      row(fields) unless fields.all?("*")
    end

    # --- reference records

    def reference_records
      work = flow.work
      [
        *composer_names.map { |name| "!!!COM: #{name}" },
        composer_dates && "!!!CDT: #{composer_dates}",
        "!!!OTL: #{flow.name}",
        work&.catalog_number && "!!!SCT: #{work.catalog_number}",
        work&.year && "!!!ODT: #{work.year}"
      ].compact
    end

    def composers
      flow.work ? flow.work.credits.for(:composer).map(&:person) : []
    end

    def composer_names
      return composers.map(&:sort_name) if flow.work

      flow.composer ? [flow.composer.to_s] : []
    end

    def composer_dates
      return unless composers.length == 1

      person = composers.first
      "#{person.birth_year}/-#{person.death_year}/" if person.birth_year && person.death_year
    end

    # --- header

    def header_rows
      [
        *grouping_rows,
        kern_row_unless_null { |column| InstrumentCodes.code_field(column.voice.part.instrument) },
        kern_row_unless_null { |column| player_name(column) },
        kern_row_unless_null { |column| ClefCodes.clef_field(clef_at(column.staff, first_bar)) },
        kern_row { plan.first_measure_key.signature },
        kern_row_unless_null { plan.first_measure_key.designation },
        kern_row { MeterReader.meter_field(plan.first_measure_meter) },
        kern_row { TempoReader.tempo_field(flow.tempo_at(first_bar)) }
      ].compact
    end

    def player_name(column)
      name = column.voice.part.player&.name
      name && InstrumentCodes.name_field(name)
    end

    def grouping_rows
      return [] unless grouped?

      [kern_row { |column| "*part#{column.part_number}" }, kern_row { |column| "*staff#{staff_number(column.staff)}" }]
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
    def clef_at(staff, bar_number)
      staff.clef_at(bar_number) || fallback_clefs[staff.object_id]
    end

    def fallback_clefs
      @fallback_clefs ||= columns.select(&:kern?).each_with_object({}) do |column, clefs|
        clefs[column.staff.object_id] ||= HeadMusic::Notation::ClefSelector.for(column.voice)
      end
    end

    # --- body

    def body_rows
      written_bars.each_with_index.flat_map do |bar_number, index|
        rows = []
        rows << row(fields_for_all(barline(bar_number, index))) unless pickup?(bar_number)
        rows.concat(change_rows(bar_number)) if bar_number > plan.bar_numbers.first
        rows.concat(data_rows(bar_number))
      end
    end

    def first_bar
      plan.bar_numbers.first
    end

    def written_bars
      @written_bars ||= bar_lengths.keys.reject { |bar_number| pickup?(bar_number) && pickup_start.nil? }
    end

    def pickup?(bar_number)
      bar_number == PICKUP_BAR && first_bar == PICKUP_BAR
    end

    # A barline opening the first written bar is invisible unless it opens a
    # repeat; a pickup has no barline before it at all.
    def barline(bar_number, index)
      return "=#{bar_number}#{bar_at(bar_number).starts_repeat? ? "!|:" : "-"}" if index.zero?

      "=#{bar_number}#{barline_style(bar_at(bar_number - 1).ends_repeat?, bar_at(bar_number).starts_repeat?)}"
    end

    def barline_style(ends, starts)
      return ":|!|:" if ends && starts
      return ":|!" if ends

      starts ? "!|:" : ""
    end

    def final_style
      bar_at(written_bars.last).ends_repeat? ? ":|!" : ""
    end

    def bar_at(bar_number)
      @bars ||= flow.bars(plan.bar_numbers.last).to_h { |bar| [bar.number, bar] }
      @bars.fetch(bar_number)
    end

    def change_rows(bar_number)
      key = plan.measure_key_changes[bar_number]
      [
        kern_row_unless_null { |column| clef_change(column, bar_number) },
        kern_row_unless_null { |column| staff_change(column, bar_number) },
        key && kern_row { key.signature },
        key && kern_row_unless_null { key.designation },
        plan.measure_time_changes[bar_number] && kern_row { MeterReader.meter_field(plan.measure_time_changes[bar_number]) },
        flow.tempo_changes[bar_number] && kern_row { TempoReader.tempo_field(flow.tempo_changes[bar_number]) }
      ].compact
    end

    def clef_change(column, bar_number)
      clef = column.voice.staff_at(bar_number).clef_changes[bar_number]
      clef && ClefCodes.clef_field(clef)
    end

    def staff_change(column, bar_number)
      staff = column.voice.staff_at(bar_number)
      "*staff#{staff_number(staff)}" unless staff.equal?(column.voice.staff_at(bar_number - 1))
    end

    def data_rows(bar_number)
      events = kern_events(bar_number)
      offsets = events.values.flatten.map { |event| Rational(event.offset) }.uniq.sort
      offsets.map do |offset|
        row(columns.map { |column| field(column, events.fetch(column.voice), offset) })
      end
    end

    def field(column, events, offset)
      event = events.find { |candidate| candidate.offset == offset }
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

    def kern_events(bar_number)
      columns.select(&:kern?).to_h do |column|
        events = voice_events(column.voice).fetch(bar_number)
        [column.voice, pickup?(bar_number) ? trimmed(events) : events]
      end
    end

    def trimmed(events)
      events.select { |event| event.finish > pickup_start }.flat_map do |event|
        (event.offset < pickup_start) ? VoiceEvents.rests(pickup_start, event.finish) : [event]
      end
    end

    # Where the pickup's first note sounds, or nil when the pickup bar
    # holds nothing but silence.
    def pickup_start
      return @pickup_start if defined?(@pickup_start)

      onsets = event_sources.values.flat_map { |source| source.placed.fetch(PICKUP_BAR, []) }.reject(&:rest?).map(&:offset)
      @pickup_start = first_bar.zero? ? onsets.min : nil
    end

    def voice_events(voice)
      @voice_events ||= {}
      @voice_events[voice] ||= event_sources.fetch(voice).by_bar(bar_lengths)
    end

    def event_sources
      @event_sources ||= flow.voices.to_h { |voice| [voice, VoiceEvents.new(voice)] }
    end

    # Every bar's full length, except the last, which ends where the longest
    # voice does.
    def bar_lengths
      @bar_lengths ||= begin
        last_bar, last_offset = event_sources.values.filter_map(&:finish).max
        (first_bar..last_bar).to_h do |bar_number|
          [bar_number, (bar_number == last_bar) ? last_offset : full_length(bar_number)]
        end
      end
    end

    def full_length(bar_number)
      meter = plan.effective_meter(bar_number)
      Rational(meter.top_number, meter.bottom_number)
    end
  end
end
