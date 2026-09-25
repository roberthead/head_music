# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Interprets a **kern string as a HeadMusic::Content::Flow.
  class Parser
    def initialize(kern_string)
      @kern_string = kern_string
    end

    def flow
      @flow ||= build_flow
    end

    private

    def build_flow
      ensure_input_present
      Document.new(Lexer.new(@kern_string).records)
      raise UnsupportedFeatureError, "kern import is not implemented yet"
    end

    # Checked on the raw bytes: String#strip raises on invalid UTF-8, and
    # that case belongs to the Lexer's encoding guard.
    def ensure_input_present
      return unless @kern_string.to_s.b.strip.empty?

      raise ParseError, "kern input is blank"
    end
  end
end
