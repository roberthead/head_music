# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Hands a tune's tokens to the parser voice by voice. The V: lines route
  # each token to its voice, and are spent doing so; then the voices advance
  # together rather than one line after another, so a field one voice states
  # is in force before another places the bar it governs, and a tie, slur, or
  # tuplet carries across a V: line.
  class VoiceReplay
    # What a tune may hold before its first voice, marking the start of the
    # music rather than a voice.
    UNVOICED_TYPES = %i[tempo annotation part_label meter key].freeze

    def initialize(voices)
      @voices = voices
    end

    # Yields each token with its voice current, or with none where the
    # token comes before any voice.
    def each(tokens, &block)
      queues = route(tokens, &block).reject(&:done?)
      until queues.empty?
        queue = queues.min_by(&:sort_key)
        @voices.enter(queue.state)
        yield queue.take
        queues = queues.reject(&:done?)
      end
    end

    private

    def route(tokens)
      streams = Hash.new { |hash, state| hash[state] = [] }
      tokens.each do |token|
        if token.type == :voice_change
          @voices.switch_to(token.voice_id) if token.voice_id
        elsif @voices.any? || !UNVOICED_TYPES.include?(token.type)
          streams[@voices.current] << token
        else
          yield token
        end
      end
      @voices.map { |state| VoiceTokens.new(state, streams[state]) }
    end
  end
end
