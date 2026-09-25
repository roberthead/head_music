# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # One live kern track's place in the file: the layer its tokens go to,
  # when the note it last attacked stops sounding, and the tie chain it
  # has open.
  #
  # A tie chain ([, _, ]) becomes one placement whose rhythmic value
  # carries each tied link, as ABC's tie handling does, and it may cross
  # any number of barlines.
  class VoiceCursor
    attr_reader :layer
    attr_accessor :busy_until

    def initialize(layer, busy_until)
      @layer = layer
      @busy_until = busy_until
      @tie = nil
      @tie_line = nil
    end

    # Answers the event the token attacked, or nil when it continued a tie.
    def read(token, time, line)
      @busy_until = time + token.fraction
      return continue_tie(token, line) if %i[middle end].include?(token.tie)

      ensure_tie_closed
      event = layer.add(time, token)
      open_tie(event, line) if token.tie == :start
      event
    end

    def ensure_tie_closed
      return unless @tie

      raise ParseError.new("A tie is never closed", line_number: @tie_line, snippet: "[")
    end

    private

    def open_tie(event, line)
      @tie = event
      @tie_line = line
    end

    def continue_tie(token, line)
      mark = (token.tie == :end) ? "]" : "_"
      raise ParseError.new("#{mark} continues a tie that was never opened", line_number: line, snippet: mark) unless @tie
      unless names(@tie.pitches) == names(token.pitches)
        raise ParseError.new("A tie must connect notes of the same pitch", line_number: line, snippet: mark)
      end

      @tie.rhythmic_value = @tie.rhythmic_value.append_tied(token.rhythmic_value)
      @tie.fraction += token.fraction
      @tie = nil if token.tie == :end
      nil
    end

    def names(pitches)
      pitches.map(&:to_s).sort
    end
  end
end
