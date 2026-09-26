# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Maps articulation, ornament, and note-dynamic keys to the MusicXML
  # elements NoteWriter marks a note with.
  module MarkingWriter
    ARTICULATION_ELEMENTS = {
      "staccato" => "staccato",
      "staccatissimo" => "staccatissimo",
      "accent" => "accent",
      "tenuto" => "tenuto",
      "marcato" => "strong-accent"
    }.freeze

    # <mordent> is the sign with the vertical line, the lower mordent;
    # MusicXML names the upper one <inverted-mordent>.
    ORNAMENT_ELEMENTS = {
      "trill" => "trill-mark",
      "mordent" => "mordent",
      "inverted_mordent" => "inverted-mordent",
      "turn" => "turn"
    }.freeze

    # A note-dynamic accent's element is its own key: <sf/>, <sfz/>, <rfz/>, <fp/>.
    DYNAMIC_ELEMENTS = {
      "sf" => "sf",
      "sfz" => "sfz",
      "rfz" => "rfz",
      "fp" => "fp"
    }.freeze

    module_function

    def articulation_element(articulation)
      ARTICULATION_ELEMENTS.fetch(articulation.name_key)
    end

    def ornament_element(ornament)
      ORNAMENT_ELEMENTS.fetch(ornament.name_key)
    end

    def dynamic_element(dynamic)
      DYNAMIC_ELEMENTS.fetch(dynamic.name_key)
    end
  end
end
