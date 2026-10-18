module HeadMusic::Notation::MEI
  # The @accid or @accid.ges of every note. Each staff's bars are walked in
  # onset order across all their layers, grace notes before their note, from
  # the part's written key: a note shows its accidental unless the key or an
  # earlier note in the bar at that letter and octave already implies it.
  # Chord members that clash (see ChordClashes) each show their accidental,
  # and the bar remembers the highest.
  class AccidentalPlan
    WRITTEN = {-2 => "ff", -1 => "f", 0 => "n", 1 => "s", 2 => "x"}.freeze
    GESTURAL = {-2 => "ff", -1 => "f", 0 => "n", 1 => "s", 2 => "ss"}.freeze
    SHARP_ORDER = HeadMusic::Rudiment::KeySignature::ORDERED_LETTER_NAMES_OF_SHARPS

    Note = Data.define(:id, :pitch, :continuation, :clashing) do
      def place
        HeadMusic::Notation::ChordClashes.place(pitch)
      end

      def semitones
        pitch.alteration_semitones.to_i
      end

      # Whether it shows its accidental where the key and the bar imply the
      # alteration +implied+.
      def shown?(implied)
        !continuation && (clashing || implied != semitones)
      end

      def attributes(implied)
        return {"accid" => WRITTEN.fetch(semitones)} if shown?(implied)
        return {} if semitones.zero? && implied.zero?

        {"accid.ges" => GESTURAL.fetch(semitones)}
      end
    end

    # Each letter's alteration in a key of +fifths+; fifths past seven double
    # the letters from the start of the order again.
    def self.key_alterations(fifths)
      direction = fifths <=> 0
      order = direction.negative? ? SHARP_ORDER.reverse : SHARP_ORDER
      order.each_with_index.to_h { |letter, index| [letter, direction * [(fifths.abs - index + 6) / 7, 0].max] }
    end

    def initialize(plan)
      @plan = plan
      @attributes_by_id = {}
      plan.staff_entries.product(plan.bar_numbers.to_a).each { |entry, bar_number| walk(entry, bar_number) }
    end

    def event_attributes(node)
      attributes_by_id.fetch(node.id, {})
    end

    private

    attr_reader :plan, :attributes_by_id

    def walk(entry, bar_number)
      key = self.class.key_alterations(plan.written_key_event(entry.part, bar_number).signature)
      memory = Hash.new { |_, (letter, _)| key.fetch(letter, 0) }
      notes(entry, bar_number).each do |note|
        place = note.place
        implied = memory[place]
        memory[place] = note.semitones if note.shown?(implied)
        attributes_by_id[note.id] = note.attributes(implied)
      end
    end

    def notes(entry, bar_number)
      items = plan.layer_voices(entry, bar_number).flat_map { |voice| plan.items(voice, bar_number) }.reject(&:rest?)
      keyed = items.flat_map { |item| item_notes(item) }
      keyed.sort_by.with_index { |(sort_key, _), index| [*sort_key, index] }.map(&:last)
    end

    # The notes of each grace note of an item, and then of the item itself.
    def item_notes(item)
      pieces = item.graces.each_with_index.map { |grace, index| plan.grace_note_ids(grace, plan.grace_id(item, index)) }
      [*pieces, plan.note_ids(item)].each_with_index.flat_map { |note_ids, index| piece_notes(item, index, note_ids) }
    end

    # Grace notes sound before every voice's note at their onset.
    def piece_notes(item, index, note_ids)
      onset = item.link.offset
      sort_key = (index < item.graces.length) ? [onset, 0, index] : [onset, 1, 0]
      clashes = HeadMusic::Notation::ChordClashes.among(note_ids.map(&:first))
      note_ids.map { |pitch, id| [sort_key, Note.new(id, pitch, item.tied_into?(index, pitch), clashes.include?(pitch))] }
    end
  end

  EventWriter.attribute_sources << AccidentalPlan
end
