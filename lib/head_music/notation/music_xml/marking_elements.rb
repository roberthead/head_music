# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Maps articulation, ornament, and note-dynamic keys to the MusicXML
  # elements a note is marked with, and back. Each table's elements are
  # unique, so its inverse is too.
  module MarkingElements
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

    ARTICULATIONS_BY_ELEMENT = ARTICULATION_ELEMENTS.invert.freeze
    ORNAMENTS_BY_ELEMENT = ORNAMENT_ELEMENTS.invert.freeze
    DYNAMICS_BY_ELEMENT = DYNAMIC_ELEMENTS.invert.freeze

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

    def articulation(element)
      key = ARTICULATIONS_BY_ELEMENT[element]
      key && HeadMusic::Rudiment::Articulation.get(key)
    end

    def ornament(element)
      key = ORNAMENTS_BY_ELEMENT[element]
      key && HeadMusic::Rudiment::Ornament.get(key)
    end

    def dynamic(element)
      key = DYNAMICS_BY_ELEMENT[element]
      key && HeadMusic::Rudiment::Dynamic.get(key)
    end
  end
end
