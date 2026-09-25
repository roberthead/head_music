# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # A Staff, a Voice, or the implicit top level, and the stream the reader
  # collects into while it is open. It yields a voice when it holds music,
  # or when it is an explicit context with no children (an empty
  # \new Staff { } is a legitimate silent voice).
  class VoiceContext
    attr_reader :role, :stream, :group, :group_staff
    attr_accessor :children

    # A group is the \new PianoStaff or \new StaffGroup this context is; a
    # group staff is the staff of one that this context's music is written on.
    def initialize(document, role, explicit:, group: nil, group_staff: nil)
      @document = document
      @role = role
      @stream = document.add_stream(role)
      @stream.group_staff = group_staff
      @explicit = explicit
      @group = group
      @group_staff = group_staff
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
