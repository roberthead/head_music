# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # One voice's place in the parser's replay: the tokens it has left, and the
  # state they are read into.
  class VoiceTokens
    TIMED_TYPES = %i[note chord rest invisible_rest].freeze

    attr_reader :state

    def initialize(state, tokens)
      @state = state
      @tokens = tokens.dup
    end

    def done?
      @tokens.empty?
    end

    def take
      @tokens.shift
    end

    # Fields and bar lines are read before the notes at the same position,
    # so a bar is placed under the meter and key that govern it.
    def sort_key
      [state.cursor, TIMED_TYPES.include?(@tokens.first.type) ? 1 : 0]
    end
  end
end
