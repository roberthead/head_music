# Reads and renders MEI documents as HeadMusic::Content flows
module HeadMusic::Notation::MEI
  # Interprets the one score in an MEI document's body as a flow. A document
  # of several scores raises, naming how many; parse_book reads each.
  def self.parse(string)
    Parser.new(string).flow
  end

  # One flow for each score in the body, in document order: nested <mdiv>s,
  # <group>s of <music>, and each <mei> of a <meiCorpus>.
  def self.parse_book(string)
    Parser.new(string).flows
  end

  # +transposed:+ says the flow's pitches are already the written ones.
  # +arranger:+ is a name or a list of names, each its own credit.
  def self.render(flow, **options)
    Writer.new([flow], **options).to_s
  end

  # Raised when an MEI document cannot be read. Only malformed XML names a
  # line; everything else names its measure, staff, and element.
  class ParseError < HeadMusic::Notation::ParseError
    attr_reader :line_number, :measure, :staff, :element

    def self.label(element)
      return element unless element.is_a?(REXML::Element)

      id = begin
        element.attributes["xml:id"]
      rescue RuntimeError
        nil
      end
      id ? %(<#{element.name} xml:id="#{id[0, 64]}">) : "<#{element.name}>"
    end

    def initialize(message, line_number: nil, measure: nil, staff: nil, element: nil)
      @line_number = line_number
      @measure = measure
      @staff = staff
      @element = self.class.label(element)
      super([message, location].compact.join(" "))
    end

    private

    def location
      return "(line #{line_number})" if line_number

      where = [measure && "measure #{measure}", staff && "staff #{staff}", element].compact
      "(#{where.join(", ")})" unless where.empty?
    end
  end

  # Raised for valid MEI that this reader cannot read without changing the
  # music
  class UnsupportedFeatureError < ParseError; end

  # Raised when a flow cannot be expressed in the supported MEI subset
  class RenderError < HeadMusic::Notation::RenderError; end
end

# The writers that own the extension hooks load first, so that a feature file
# can register with them as it loads.
%w[markup event_writer measure_writer score_def_writer section_writer xml_reading].each do |name|
  require_relative "mei/#{name}"
end
Dir[File.join(__dir__, "mei", "*.rb")].sort.each { |file| require file }
