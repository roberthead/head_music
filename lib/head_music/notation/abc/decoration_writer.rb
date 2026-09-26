# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Writes the decorations before a voice event: the level from its voice's
  # or part's dynamic events, then its articulations, ornaments, and note
  # dynamic. Staccato takes its shorthand dot; the rest are spelled out, since
  # the shorthand letters can be redefined by a U: field.
  class DecorationWriter
    NAMES = {
      "staccatissimo" => "wedge",
      "mordent" => "lowermordent",
      "inverted_mordent" => "uppermordent"
    }.freeze

    def initialize(voice)
      @placement = HeadMusic::Notation::DynamicPlacement.new(voice, include_part: true)
    end

    def prefix(voice_event)
      markings = [@placement.level_for(voice_event), *voice_event.articulations, *voice_event.ornaments, voice_event.note_dynamic]
      markings.compact.map { |marking| decoration(marking.name_key) }.join
    end

    private

    def decoration(name_key)
      return "." if name_key == "staccato"

      "!#{NAMES.fetch(name_key, name_key)}!"
    end
  end
end
