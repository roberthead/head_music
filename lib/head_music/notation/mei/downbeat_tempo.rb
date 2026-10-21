module HeadMusic::Notation::MEI
  # The tempo a measure's first <tempo> on its downbeat states, by @tstamp
  # or at a @startid naming an entry that starts the measure, or one of its
  # notes. One in the middle of the bar is skipped, as is a gradual change
  # and a tempo of ramp or "a tempo" words alone, which are no tempo.
  module DownbeatTempo
    module_function

    # +entries+ are the measure's layers' entries; +index+ the IdIndex;
    # +editorial+ reads each <tempo>'s text.
    def tempo(controls, entries, meter, index, editorial, **where)
      tempos = controls.select { |control| control.name == "tempo" && !TempoReading.continuous?(control, **where) }
      return if tempos.empty?

      firsts = first_onsets(entries)
      tempos.lazy
        .select { |control| downbeat?(control, meter, firsts, index, where) }
        .filter_map { |control| step(TempoReading.tempo(control, editorial.text(control), **where)) }.first
    end

    def step(tempo)
      tempo unless tempo && !tempo.metronome_mark? && HeadMusic::Notation::TempoMarkReading.word(tempo.text)
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
