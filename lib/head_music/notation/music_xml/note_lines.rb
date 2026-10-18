# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # The children of a <note> that the note and grace note writers both write.
  module NoteLines
    include HeadMusic::Notation::XmlText

    private

    # A <voice> or <staff>, omitted where there is no number to write.
    def number_line(tag, number)
      number && "#{INDENT * 4}<#{tag}>#{number}</#{tag}>"
    end

    # A <tie> is heard and a <tied> is drawn; each stops before it starts.
    def tie_lines(tag, depth, ties)
      %i[stop start].filter_map { |type| %(#{INDENT * depth}<#{tag} type="#{type}"/>) if ties[type] }
    end

    def slur_line(type, number)
      %(#{INDENT * 5}<slur type="#{type}" number="#{number}"/>)
    end

    def marking_group_lines(tag, markings, element_for)
      return [] if markings.empty?

      [
        "#{INDENT * 5}<#{tag}>",
        *markings.map { |marking| "#{INDENT * 6}<#{element_for.call(marking)}/>" },
        "#{INDENT * 5}</#{tag}>"
      ]
    end

    def notations_lines(lines)
      return [] if lines.empty?

      ["#{INDENT * 4}<notations>", *lines, "#{INDENT * 4}</notations>"]
    end
  end
end
