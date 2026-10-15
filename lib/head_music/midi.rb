# Renders flows as Standard MIDI Files. MIDI holds a performance, not its
# notation: keys rather than spellings, and ticks rather than note values.
module HeadMusic::MIDI
  # Raised when bytes cannot be read as a Standard MIDI File, naming the byte
  # offset where reading failed.
  class ParseError < HeadMusic::Notation::ParseError
    attr_reader :offset

    def initialize(message, offset: nil)
      @offset = offset
      super(offset ? "#{message} (byte #{offset})" : message)
    end
  end

  # A subclass of the notation writers' error, so one rescue covers every writer.
  class RenderError < HeadMusic::Notation::RenderError; end
end

# Helper classes load in name order; they reference one another only at runtime.
Dir[File.join(__dir__, "midi", "*.rb")].sort.each { |file| require file }
