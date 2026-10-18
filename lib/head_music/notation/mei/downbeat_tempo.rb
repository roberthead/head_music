module HeadMusic::Notation::MEI
  # The tempo a measure's first <tempo> on its downbeat states, by @tstamp
  # or at a @startid naming an entry that starts the measure, or one of its
  # notes. One in the middle of the bar, or with text only, is skipped.
  module DownbeatTempo
    module_function

    # +entries+ are the measure's layers' entries; +index+ the IdIndex.
    def tempo(controls, entries, meter, index, **where)
      tempos = controls.select { |control| control.name == "tempo" }
      return if tempos.empty?

      firsts = first_onsets(entries)
      tempos.lazy
        .select { |control| downbeat?(control, meter, firsts, index, where) }
        .filter_map { |control| TempoReading.tempo(control, **where) }.first
    end

    def downbeat?(control, meter, firsts, index, where)
      tstamp = AttributeValues.read(control, "tstamp", **where, element: control, count: meter.top_number)
      return tstamp <= 1 if tstamp

      reference = XmlReading.attribute(control, "startid", element: control)
      reference.nil? || firsts.key?(index.resolve(reference, **where, element: control))
    end

    def first_onsets(entries)
      entries.each_with_object({}.compare_by_identity) do |entry, firsts|
        next unless entry.cursor.zero? && !entry.grace

        [entry.element, *entry.notes].each { |element| firsts[element] = true }
      end
    end
  end
end
