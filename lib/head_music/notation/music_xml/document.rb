require_relative "xml_reading"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # A parsed score as a list of parts, each a list of measures, whichever
  # way the document is organized. A score-timewise document's measures hold
  # parts, so each <measure>'s <part> is appended to its part's list, taking
  # its number and implicit flag from the <measure> around it; nothing is
  # copied, and the element a measure reads its music from is that <part>.
  #
  # A part with no notes is left out, and a part missing from the
  # <part-list> has no <score-part>, so it reads with no name.
  class Document
    include XmlReading

    Part = Data.define(:id, :score_part, :measures)
    Measure = Data.define(:element, :number, :implicit) do
      alias_method :implicit?, :implicit
    end

    attr_reader :root

    def initialize(xml)
      @root = xml.root
    end

    def timewise?
      root.name == "score-timewise"
    end

    def parts
      @parts ||= measures_by_part.filter_map do |id, measures|
        Part.new(id, score_parts[id], measures) if measures.any? { |measure| first_child(measure.element, "note") }
      end
    end

    # A child of the root, such as <work> or <identification>.
    def header(name)
      first_child(root, name)
    end

    def credits
      children(root, "credit")
    end

    private

    def score_parts
      @score_parts ||= begin
        part_list = header("part-list")
        part_list ? children(part_list, "score-part").to_h { |score_part| [attribute(score_part, "id"), score_part] } : {}
      end
    end

    def measures_by_part
      timewise? ? timewise_measures : partwise_measures
    end

    def partwise_measures
      children(root, "part").to_h do |part|
        [attribute(part, "id"), children(part, "measure").map { |measure| measure_for(measure, measure) }]
      end
    end

    def timewise_measures
      children(root, "measure").each_with_object({}) do |measure, parts|
        children(measure, "part").each do |part|
          (parts[attribute(part, "id")] ||= []) << measure_for(part, measure)
        end
      end
    end

    def measure_for(element, measure)
      Measure.new(element, attribute(measure, "number"), attribute(measure, "implicit") == "yes")
    end
  end
end
