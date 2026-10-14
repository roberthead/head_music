# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Writes the marks after a voice event's first note: the articulations as
  # shorthands, the ornaments, and the sforzando.
  # The names come from the MarkReader's tables, so whatever is written reads
  # back as itself.
  module MarkWriter
    module_function

    def token(voice_event)
      [
        *voice_event.articulations.map { |articulation| articulation_token(articulation) },
        *voice_event.ornaments.map { |ornament| "\\#{MarkReader::ORNAMENTS_BY_COMMAND.key(ornament.name_key)}" },
        voice_event.note_dynamic && "\\#{voice_event.note_dynamic.name_key}"
      ].compact.join
    end

    def articulation_token(articulation)
      "-#{MarkReader::ARTICULATIONS_BY_SHORTHAND.key(articulation.name_key)}"
    end
  end
end
