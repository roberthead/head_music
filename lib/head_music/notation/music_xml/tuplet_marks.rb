require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # The <time-modification> and <tuplet> marks of every written component
  # under a tuplet ratio, keyed as the render plan keys components: by
  # segment and component index. Each bracket TupletBrackets draws starts on
  # its first component and stops on its last, numbered by its voice's place
  # in the part, since a voice's brackets never overlap but two voices'
  # may, and a bracket may cross measures.
  class TupletMarks
    include XmlText

    Mark = Data.define(:ratio, :normal_type, :normal_dots, :starts, :stops)

    def initialize(plan)
      @plan = plan
      @marks = {}
      plan.flow.parts.each do |part|
        part.voices.each_with_index { |voice, index| mark_voice(voice, index + 1) }
      end
    end

    def at(segment, component_index)
      @marks[[segment, component_index]]
    end

    # Every note under a ratio carries one, the members of a chord too.
    def time_modification_lines(mark)
      return [] unless mark

      [
        "#{INDENT * 4}<time-modification>",
        "#{INDENT * 5}<actual-notes>#{mark.ratio.actual}</actual-notes>",
        "#{INDENT * 5}<normal-notes>#{mark.ratio.normal}</normal-notes>",
        mark.normal_type && "#{INDENT * 5}<normal-type>#{mark.normal_type}</normal-type>",
        *Array.new(mark.normal_dots) { "#{INDENT * 5}<normal-dot/>" },
        "#{INDENT * 4}</time-modification>"
      ].compact
    end

    # A bracket of one note starts and stops on it.
    def tuplet_lines(mark)
      return [] unless mark

      [*mark.starts.map { |number| tuplet_line("start", number) }, *mark.stops.map { |number| tuplet_line("stop", number) }]
    end

    private

    attr_reader :plan

    def tuplet_line(type, number)
      %(#{INDENT * 5}<tuplet type="#{type}" number="#{number}"/>)
    end

    def mark_voice(voice, number)
      segments = HeadMusic::Notation::BarSplitter.segments(voice.voice_events)
      HeadMusic::Notation::TupletBrackets.for(voice, segments, error_class: RenderError).each do |bracket|
        bracket.links.each do |link|
          @marks[[link.segment, link.index]] = mark_for(bracket, link, number)
        end
      end
    end

    def mark_for(bracket, link, number)
      unit = bracket.unit
      same_unit = unit.nil? || (unit.unit_name == link.rhythmic_value.unit_name && unit.dots == link.rhythmic_value.dots)
      Mark.new(
        ratio: link.ratio,
        normal_type: same_unit ? nil : DurationWriter::TYPES_BY_UNIT_NAME.fetch(unit.unit_name),
        normal_dots: same_unit ? 0 : unit.dots,
        starts: link.equal?(bracket.first) ? [number] : [],
        stops: link.equal?(bracket.last) ? [number] : []
      )
    end
  end
end
