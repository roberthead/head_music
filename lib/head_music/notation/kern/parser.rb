# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Interprets a **kern string as a HeadMusic::Content::Flow.
  #
  # The pipeline validates in stages -- blank input, lexing, then the
  # spine structure of the whole file -- before the FlowBuilder reads any
  # music, and the FlowBuilder raises before returning, so a caller never
  # receives a partially built flow.
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
      document = Document.new(Lexer.new(@kern_string).records)
      FlowBuilder.new(document).flow
    end

    # Checked on the raw bytes: String#strip raises on invalid UTF-8, and
    # that case belongs to the Lexer's encoding guard.
    def ensure_input_present
      return unless @kern_string.to_s.b.strip.empty?

      raise ParseError, "kern input is blank"
    end
  end
end
