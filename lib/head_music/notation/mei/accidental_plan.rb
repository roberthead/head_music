module HeadMusic::Notation::MEI
  # The @accid or @accid.ges of every note. Each staff's bars are walked in
  # onset order across all their layers, grace notes before their note, from
  # the part's written key: a note shows its accidental unless the key or an
  # earlier note in the bar at that letter and octave already implies it.
  class AccidentalPlan
    WRITTEN = {-2 => "ff", -1 => "f", 0 => "n", 1 => "s", 2 => "x"}.freeze
    GESTURAL = {-2 => "ff", -1 => "f", 0 => "n", 1 => "s", 2 => "ss"}.freeze
    SHARP_ORDER = %w[F C G D A E B].freeze

    Note = Data.define(:id, :pitch, :continuation)

    def initialize(plan)
      @plan = plan
      @attributes_by_id = {}
      plan.staff_entries.each do |entry|
        plan.bar_numbers.each { |bar_number| walk(entry, bar_number) }
      end
    end

    def event_attributes(node)
      return {} unless node.kind == :note

      attributes_by_id.fetch(node.id, {})
    end

    private

    attr_reader :plan, :attributes_by_id

    def walk(entry, bar_number)
      key = key_alterations(plan.written_key_event(entry.part, bar_number).signature)
      memory = {}
      notes(entry, bar_number).each do |note|
        attributes_by_id[note.id] = attributes(note, key, memory)
      end
    end

    def attributes(note, key, memory)
      pitch = note.pitch
      letter = pitch.letter_name.to_s
      semitones = pitch.alteration_semitones.to_i
      implied = memory.fetch([letter, pitch.register]) { key.fetch(letter, 0) }
      if !note.continuation && implied != semitones
        memory[[letter, pitch.register]] = semitones
        return {"accid" => WRITTEN.fetch(semitones)}
      end
      return {} if semitones.zero? && implied.zero?

      {"accid.ges" => GESTURAL.fetch(semitones)}
    end

    # Fifths past seven double the letters from the start of the order again.
    def key_alterations(fifths)
      order = fifths.negative? ? SHARP_ORDER.reverse : SHARP_ORDER
      direction = fifths.negative? ? -1 : 1
      order.each_with_index.to_h { |letter, index| [letter, direction * [(fifths.abs - index + 6) / 7, 0].max] }
    end

    def notes(entry, bar_number)
      keyed = plan.layer_voices(entry, bar_number).flat_map do |voice|
        plan.items(voice, bar_number).reject(&:rest?).flat_map { |item| item_notes(item) }
      end
      keyed.each_with_index.sort_by { |(sort_key, _), index| [*sort_key, index] }.map { |(_, note), _| note }
    end

    def item_notes(item)
      onset = item.link.offset
      [*grace_notes(item, onset), *plan.note_ids(item).map { |pitch, id|
        [[onset, 1, 0], Note.new(id, pitch, continued?(item, pitch))]
      }]
    end

    def grace_notes(item, onset)
      graces = item.graces
      graces.each_with_index.flat_map do |grace, index|
        tied_in = (index.positive? && graces[index - 1].tied?) ? graces[index - 1].pitches : []
        plan.grace_note_ids(grace, plan.grace_id(item, index)).map do |pitch, id|
          [[onset, 0, index], Note.new(id, pitch, tied_in.include?(pitch))]
        end
      end
    end

    def continued?(item, pitch)
      return true if %w[m t].include?(item.tie)

      last = item.graces.last
      !!(last&.tied? && last.pitches.include?(pitch))
    end
  end

  EventWriter.attribute_sources << AccidentalPlan
end
