# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads \tuplet n/d [span] and the older \times d/n, around the music the
  # MusicReader reads for them, and \tupletSpan, which gives later tuplets of
  # the voice a span of their own. The stream gives the music inside the
  # ratio, and the placer brackets it once the voice is placed.
  class TupletReader
    def initialize(cursor)
      @cursor = cursor
      @duration_reader = DurationReader.new
    end

    def read(context)
      token = cursor.advance
      ratio = ratio(token)
      stream = context.stream
      raise cursor.unsupported("Nested tuplets are not supported", token) if stream.tuplet?

      span = duration_reader.tuplet_span_fraction(token) || stream.tuplet_span
      raise cursor.error("#{token.lexeme} expects music", cursor.peek || token) if [nil, :close_brace].include?(cursor.peek&.type)
      return yield unless ratio

      stream.open_tuplet(ratio, span, token.line)
      yield
      stream.close_tuplet(token.line)
    end

    def read_span(context)
      token = cursor.advance
      if token.duration
        context.stream.tuplet_span = duration_reader.tuplet_span_fraction(token)
      elsif cursor.peek&.type == :command && cursor.peek.lexeme == "default"
        cursor.advance
        context.stream.tuplet_span = nil
      else
        raise cursor.error("\\tupletSpan expects a duration or \\default", cursor.peek || token)
      end
    end

    private

    attr_reader :cursor, :duration_reader

    # \tuplet writes actual/normal and \times normal/actual. A ratio of one
    # changes nothing, so its music is read plainly.
    def ratio(token)
      raise cursor.error("#{token.lexeme} expects a fraction", token) unless token.fraction

      numbers = token.fraction.split("/").map(&:to_i)
      raise cursor.error("#{token.lexeme} expects a positive fraction", token) unless numbers.all?(&:positive?)

      numbers.reverse! if token.lexeme == "\\times"
      HeadMusic::Rudiment::TupletRatio.get(numbers) unless numbers.uniq.length == 1
    end
  end
end
