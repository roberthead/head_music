# Parses ABC notation into HeadMusic::Content compositions
module HeadMusic::Notation::ABC
  def self.parse(abc_string)
    Parser.new(abc_string).composition
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
end

# Helper classes load in name order; they reference one another only at runtime.
Dir[File.join(__dir__, "abc", "*.rb")].sort.each { |file| require file }
