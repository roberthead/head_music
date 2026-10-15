module HeadMusic::Notation::MEI
  # Decides a part's voices once every measure is read, and adds each
  # layer's events to its voice's track in order.
  #
  # Where no measure has one layer @n holding notes on two of the part's
  # staves, the layer number alone is the voice, as MEI Export numbers it,
  # so a voice may cross from staff to staff. Otherwise the staff and layer
  # number together are the voice, as MuseScore and most encoders write a
  # piano, and a key with no notes anywhere is a placeholder that is not
  # read. Where several layers of one voice share a measure, the one with
  # notes is read, or else one with any timed event.
  #
  # A voice's role is the <label> of its <layerDef>.
  class VoiceAssignment
    include XmlReading

    def initialize(reading, editorial)
      @reading = reading
      @editorial = editorial
      @definition = reading.definition
    end

    def assign
      by_measure = @reading.layers.chunk_while { |before, after| before.measure_index == after.measure_index }
      by_staff = by_staff?(by_measure)
      noted = @reading.layers.select { |layer| layer.content.notes? }.map { |layer| key(layer, by_staff) }.uniq
      by_measure.each do |layers|
        layers.group_by { |layer| key(layer, by_staff) }.each do |key, candidates|
          next if by_staff && !noted.include?(key)

          add(@reading.track(key, label(key)), chosen(candidates))
          @reading.roles[key] ||= role(key)
        end
      end
    end

    private

    def by_staff?(by_measure)
      by_measure.any? do |layers|
        layers.select { |layer| layer.content.notes? }.group_by { |layer| layer.content.number }
          .any? { |_, same| same.map { |layer| layer.content.staff_number }.uniq.length > 1 }
      end
    end

    def key(layer, by_staff)
      by_staff ? [@definition.staff_index(layer.content.staff_number), layer.content.number] : layer.content.number
    end

    def label(key)
      key.is_a?(Array) ? "#{key.first}.#{key.last}" : key.to_s
    end

    def chosen(candidates)
      candidates.find { |layer| layer.content.notes? } || candidates.find { |layer| layer.content.placed? } || candidates.first
    end

    def add(track, layer)
      staff = @definition.staff_index(layer.staff)
      layer.entries.each do |entry, sounds, pending|
        if entry.grace
          grace = track.queue_grace(sounds: sounds.uniq, rhythmic_value: entry.rhythmic_value, slashed: entry.slashed, articulations: [], tie_starts: [])
          fill(pending, track, grace: grace)
        else
          fill(pending, track, event: add_event(track, entry, sounds, layer.measure_index, staff))
        end
      end
    end

    # A <multiRest> adds a bar-filling rest to each bar it stands for, and
    # answers the first.
    def add_event(track, entry, sounds, index, staff)
      (entry.bars || 1).times.map do |offset|
        track.add(
          measure_index: index + offset, cursor: entry.cursor, tolerance: PartReading::TOLERANCE,
          rhythmic_value: entry.fills_bar? ? nil : entry.rhythmic_value, duration: entry.duration || 0, sounds: sounds.uniq,
          fills_bar: entry.fills_bar?, cue: entry.cue, tie_starts: [], tie_stops: [], staff: staff
        )
      end.first
    end

    def fill(pending, track, event: nil, grace: nil)
      pending.each do |record|
        record.track = track
        record.event = event
        record.grace = grace
      end
    end

    def role(key)
      number = key.is_a?(Array) ? key.last : key
      staff_defs = key.is_a?(Array) ? [@definition.staff_defs.values[key.first - 1]] : @definition.staff_defs.values
      staff_defs.each do |staff_def|
        layer_def = @editorial.children_named(staff_def, "layerDef").find do |candidate|
          (AttributeValues.read(candidate, "n", element: candidate) || 1) == number
        end
        text = layer_def && layer_label(layer_def)
        return text if text
      end
      nil
    end

    def layer_label(layer_def)
      label = @editorial.children_named(layer_def, "label").first
      text = label ? @editorial.text(label) : attribute(layer_def, "label", element: layer_def)
      text unless text.to_s.strip.empty?
    end
  end
end
