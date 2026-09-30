require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Renders a bar's rehearsal mark and navigation as <direction> elements: the
  # rehearsal mark, segno, and coda sign where the measure opens, and Fine,
  # To Coda, and a D.C. or D.S. where it closes. Each sign carries the <sound>
  # that makes playback follow it.
  class NavigationWriter
    include XmlText

    SEGNO = "segno1"
    CODA = "coda1"

    delegate :bar, to: :plan

    def initialize(plan)
      @plan = plan
    end

    def opening_lines(bar_number)
      current = bar(bar_number)
      [
        *(current.rehearsal_mark ? direction_lines("<rehearsal>#{escape(current.rehearsal_mark)}</rehearsal>") : []),
        *(current.segno? ? direction_lines("<segno/>", %(segno="#{SEGNO}")) : []),
        *(current.coda? ? direction_lines("<coda/>", %(coda="#{CODA}")) : [])
      ]
    end

    def closing_lines(bar_number)
      current = bar(bar_number)
      [
        *(current.fine? ? words_lines("Fine", %(fine="yes")) : []),
        *(current.to_coda? ? words_lines("To Coda", %(tocoda="#{CODA}")) : []),
        *(current.jump ? words_lines(current.jump.to_s, jump_sound(current.jump)) : [])
      ]
    end

    private

    attr_reader :plan

    def jump_sound(jump)
      jump.da_capo? ? %(dacapo="yes") : %(dalsegno="#{SEGNO}")
    end

    def words_lines(text, sound)
      direction_lines("<words>#{escape(text)}</words>", sound)
    end

    def direction_lines(content, sound = nil)
      [
        %(#{INDENT * 3}<direction placement="above">),
        "#{INDENT * 4}<direction-type>",
        "#{INDENT * 5}#{content}",
        "#{INDENT * 4}</direction-type>",
        sound && "#{INDENT * 4}<sound #{sound}/>",
        "#{INDENT * 3}</direction>"
      ].compact
    end
  end
end
