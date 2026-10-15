# Reads and renders MusicXML documents as HeadMusic::Content flows
module HeadMusic::Notation::MusicXML
  # Interprets a MusicXML document as a flow. Raises before building on
  # anything it cannot read, so callers never receive a partial flow.
  def self.parse(string)
    Parser.new(string).flow
  end

  # +work_title:+ names the whole this flow is a movement of and
  # +movement_number:+ its place in it; alone, a flow names only itself.
  #
  # +transposed:+ says the flow's pitches are already the written ones, so that
  # each part prints its own key and a <transpose> naming what it sounds.
  def self.render(flow, **options)
    Writer.new(flow, **options).to_s
  end

  # Raised when a MusicXML document cannot be read. Elements carry no line,
  # so only malformed XML names one; everything else names its measure.
  class ParseError < HeadMusic::Notation::ParseError
    attr_reader :line_number, :measure, :part

    def initialize(message, line_number: nil, measure: nil, part: nil)
      @line_number = line_number
      @measure = measure
      @part = part
      super([message, location].compact.join(" "))
    end

    private

    def location
      return "(line #{line_number})" if line_number

      where = [measure && "measure #{measure}", part && "part #{part}"].compact
      "(#{where.join(" of ")})" unless where.empty?
    end
  end

  # Raised for valid MusicXML that this reader cannot read without changing
  # the music
  class UnsupportedFeatureError < ParseError; end

  # Raised when a flow cannot be expressed in the supported MusicXML subset
  class RenderError < HeadMusic::Notation::RenderError; end
end

# Helper classes load in name order; they reference one another only at runtime.
Dir[File.join(__dir__, "music_xml", "*.rb")].sort.each { |file| require file }
