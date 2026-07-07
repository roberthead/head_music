# Parses and renders ABC notation as HeadMusic::Content compositions
module HeadMusic::Notation::ABC
  # Parses exactly one tune. Raises when the input holds more than one.
  def self.parse(abc_string)
    Parser.new(abc_string).composition
  end

  # Parses a tune book — one or more blank-line-separated tunes.
  def self.parse_book(abc_string)
    BookParser.new(abc_string).compositions
  end

  # Renders a composition as an ABC tune string.
  def self.render(composition, **options)
    Writer.new(composition, **options).to_s
  end

  # Raised when an ABC string cannot be interpreted
  class ParseError < HeadMusic::Notation::ParseError
    attr_reader :line_number, :snippet

    def initialize(message, line_number: nil, snippet: nil)
      @line_number = line_number
      @snippet = snippet
      message = "#{message} (line #{line_number})" if line_number
      super(message)
    end
  end

  # Raised for valid ABC constructs that this parser does not support
  class UnsupportedFeatureError < ParseError; end

  # Raised when a composition cannot be expressed in the supported ABC subset
  class RenderError < HeadMusic::Notation::RenderError; end
end

# Helper classes load in name order; they reference one another only at runtime.
Dir[File.join(__dir__, "abc", "*.rb")].sort.each { |file| require file }
