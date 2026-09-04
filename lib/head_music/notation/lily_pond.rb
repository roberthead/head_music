# Parses and renders LilyPond documents as HeadMusic::Content compositions
module HeadMusic::Notation::LilyPond
  # Interprets a LilyPond document, or a bare music expression, as a
  # composition. Raises before building on anything outside the supported
  # subset, so callers never receive a partial composition.
  def self.parse(lily_pond_string)
    Parser.new(lily_pond_string).composition
  end

  # Renders a composition as a complete LilyPond source string.
  # No rendering options exist yet; keywords will be added with the first one.
  def self.render(composition, **options)
    Writer.new(composition, **options).to_s
  end

  # Raised when a LilyPond string cannot be interpreted
  class ParseError < HeadMusic::Notation::ParseError
    attr_reader :line_number, :column, :snippet

    def initialize(message, line_number: nil, column: nil, snippet: nil)
      @line_number = line_number
      @column = column
      @snippet = snippet
      message = "#{message} (line #{line_number})" if line_number
      super(message)
    end
  end

  # Raised for valid LilyPond constructs that this parser does not support
  class UnsupportedFeatureError < ParseError; end

  # Raised when a composition cannot be expressed in the supported LilyPond subset
  class RenderError < HeadMusic::Notation::RenderError; end
end

# Helper classes load in name order; they reference one another only at runtime.
Dir[File.join(__dir__, "lily_pond", "*.rb")].sort.each { |file| require file }
