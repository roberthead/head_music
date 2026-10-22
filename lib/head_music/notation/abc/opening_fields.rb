# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # The meter and key a tune opens in. A voice may state either before its
  # first note, in a body M: or K: line or an inline field, and the flow
  # opens in it rather than changing to it at the first bar, as the LilyPond
  # reader reads a \time or \key there. The first stated wins, taking the
  # voices in the order the replay does.
  class OpeningFields
    def initialize(header, tokens)
      @header = header
      @voice_order = header.voice_ids.dup
      @fields = opening_fields(tokens)
    end

    # The header's flow attributes, with any meter or key stated at the
    # opening in place of the header's.
    def flow_attributes
      @header.flow_attributes.merge({meter: meter, key_signature: key_signature}.compact)
    end

    private

    def meter
      token = first(:meter)
      Header.meter(token.lexeme, token.line) if token
    end

    def key_signature
      first(:key)&.then { |token| KeyMapper.new(token.lexeme, line_number: token.line).key_signature }
    end

    def first(type)
      @fields.select { |field| field[:token].type == type }
        .min_by { |field| [@voice_order.index(field[:voice]), field[:index]] }&.dig(:token)
    end

    # Each field read before its voice's first note, with the voice it
    # belongs to. Before any V: line, that is the first declared voice.
    def opening_fields(tokens)
      voice = @header.voice_ids.first
      started = []
      fields = []
      tokens.each_with_index do |token, index|
        if token.type == :voice_change
          voice = token.voice_id || voice
          next
        end
        @voice_order << voice unless @voice_order.include?(voice)
        if opening_field?(token)
          fields << {token: token, voice: voice, index: index} unless started.include?(voice)
        elsif VoiceTokens::TIMED_TYPES.include?(token.type)
          started << voice
        end
      end
      fields
    end

    # A K: field holding only terms such as clef=bass states no key.
    def opening_field?(token)
      token.type == :meter || (token.type == :key && KeyMapper.new(token.lexeme).key?)
    end
  end
end
