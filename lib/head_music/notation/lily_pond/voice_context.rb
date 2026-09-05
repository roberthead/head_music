# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # A Staff, a Voice, or the implicit top level, and the stream the reader
  # collects into while it is open. It yields a voice when it holds music,
  # or when it is an explicit context with no children (an empty
  # \new Staff { } is a legitimate silent voice).
  class VoiceContext
    attr_reader :role, :stream
    attr_accessor :children

    def initialize(document, role, explicit:)
      @document = document
      @role = role
      @stream = document.add_stream(role)
      @explicit = explicit
      @children = 0
    end

    # A context that yields no voice may still have collected commands;
    # dropping them silently would lose a key or meter, so they raise.
    def close
      stream.finish
      return if voice?

      document.remove_stream(stream)
      event = stream.events.find { |candidate| %i[key time].include?(candidate.kind) }
      return unless event

      raise UnsupportedFeatureError.new(
        "\\key and \\time outside a voice are not supported", line_number: event.line
      )
    end

    private

    attr_reader :document, :explicit

    def voice?
      stream.music? || (explicit && children.zero?)
    end
  end
end
