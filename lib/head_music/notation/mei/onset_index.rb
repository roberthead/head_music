module HeadMusic::Notation::MEI
  # Where each timed event read in a measure starts, by measure and the
  # staff its layer is in, sorted for bisecting, so that a control placed
  # by @tstamp finds the event starting there: the nearest within 1/1000
  # beat in the layer it names, else on its staff.
  class OnsetIndex
    BEAT_TOLERANCE = Rational(1, 1000)

    # +pending+ is the entry's Pending records, its chord tones after it.
    Onset = Data.define(:cursor, :layer, :pending)

    def initialize(readings)
      @onsets = {}
      readings.each { |reading| reading.layers.each { |layer| add(layer) } }
      @onsets.transform_values! { |onsets| onsets.each_with_index.sort_by { |onset, index| [onset.cursor, index] }.map(&:first) }
    end

    # The onsets nearest an offset, in whole notes, into a measure whose
    # beat is +unit+, or none within the tolerance.
    def at(measure_index, offset, unit, staff:, layer: nil)
      near = near(@onsets.fetch([measure_index, staff], []), offset, BEAT_TOLERANCE / unit)
      in_layer = layer ? near.select { |onset| onset.layer == layer } : []
      chosen = in_layer.empty? ? near : in_layer
      return [] if chosen.empty?

      nearest = chosen.min_by { |onset| (onset.cursor - offset).abs }.cursor
      chosen.select { |onset| onset.cursor == nearest }
    end

    private

    def add(layer)
      key = [layer.measure_index, layer.content.staff_number]
      layer.entries.each do |entry, _sounds, pending|
        (@onsets[key] ||= []) << Onset.new(entry.cursor, layer.content.number, pending) unless entry.grace
      end
    end

    def near(onsets, offset, tolerance)
      index = onsets.bsearch_index { |onset| onset.cursor >= offset - tolerance }
      found = []
      while index && index < onsets.length && onsets[index].cursor <= offset + tolerance
        found << onsets[index]
        index += 1
      end
      found
    end
  end
end
