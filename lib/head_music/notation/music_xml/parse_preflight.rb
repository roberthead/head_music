# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # The shared preflight, with MusicXML's roots and messages.
  class ParsePreflight
    ROOTS = %w[score-partwise score-timewise].freeze

    def self.check!(xml)
      HeadMusic::Notation::ParsePreflight.check!(xml, roots: ROOTS, format: "MusicXML", error_class: ParseError)
    end
  end
end
