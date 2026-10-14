# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Writes the decorations a voice event carries: its articulations,
  # ornaments, and note dynamic. Staccato takes its shorthand dot; the rest are
  # spelled out, since the shorthand letters can be redefined by a U: field.
  # Levels are placed by PositionMarks.
  class DecorationWriter
    NAMES = {
      "staccatissimo" => "wedge",
      "mordent" => "lowermordent",
      "inverted_mordent" => "uppermordent"
    }.freeze

    def prefix(voice_event)
      markings = [*voice_event.articulations, *voice_event.ornaments, voice_event.note_dynamic]
      markings.compact.map { |marking| decoration(marking.name_key) }.join
    end

    private

    def decoration(name_key)
      return "." if name_key == "staccato"

      "!#{NAMES.fetch(name_key, name_key)}!"
    end
  end
end
