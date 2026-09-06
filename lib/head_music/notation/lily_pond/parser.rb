# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Interprets a LilyPond string as a HeadMusic::Content::Flow.
  #
  # The pipeline validates in stages — blank input, lexing, delimiter
  # balance, then the document's structure and every pitch, duration, key,
  # and meter — before a flow is built, so a caller never receives a
  # reference to a partially built flow. Unsupported constructs are
  # named by the reader rather than swept up front, so one inside a
  # \layout or \midi block the reader skips never reaches a caller.
  class Parser
    def initialize(lily_pond_string)
      @lily_pond_string = lily_pond_string
    end

    def flow
      @flow ||= build_flow
    end

    private

    def build_flow
      ParsePreflight.ensure_input_present(@lily_pond_string)
      tokens = Lexer.new(@lily_pond_string).tokens
      ParsePreflight.ensure_balanced_delimiters(tokens)
      document = DocumentReader.new(tokens).document
      FlowBuilder.new(document).flow
    end
  end
end
