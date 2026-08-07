# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # The text primitives the MusicXML serializers share: the document's indent
  # unit and the character escapes XML requires in element content.
  module XmlText
    INDENT = "  "
    ESCAPES = {
      "&" => "&amp;",
      "<" => "&lt;",
      ">" => "&gt;",
      '"' => "&quot;",
      "'" => "&apos;"
    }.freeze

    private

    def escape(text)
      text.to_s.gsub(/[&<>"']/) { |character| ESCAPES[character] }
    end
  end
end
