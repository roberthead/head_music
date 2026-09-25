# Parses Humdrum **kern documents as HeadMusic::Content flows
module HeadMusic::Notation::Kern
  # Interprets a **kern document as a flow. Raises before building on
  # anything outside the supported subset, so callers never receive a
  # partial flow.
  def self.parse(kern_string)
    Parser.new(kern_string).flow
  end

  # +transposed:+ is accepted for parity with the other writers, but kern is
  # written at concert pitch, so a transposing part raises RenderError.
  def self.render(flow, transposed: false)
    Writer.new(flow, transposed: transposed).to_s
  end

  # Raised when a **kern string cannot be interpreted
  class ParseError < HeadMusic::Notation::ParseError
    attr_reader :line_number, :snippet

    def initialize(message, line_number: nil, snippet: nil)
      @line_number = line_number
      @snippet = snippet
      message = "#{message} (line #{line_number})" if line_number
      super(message)
    end
  end

  # Raised for valid **kern constructs that this parser does not support
  class UnsupportedFeatureError < ParseError; end

  # Raised when a flow cannot be expressed in the supported **kern subset
  class RenderError < HeadMusic::Notation::RenderError; end
end

# Helper classes load in name order; they reference one another only at runtime.
Dir[File.join(__dir__, "kern", "*.rb")].sort.each { |file| require file }
