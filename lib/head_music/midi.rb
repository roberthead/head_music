# Renders flows as Standard MIDI Files. MIDI holds a performance, not its
# notation: keys rather than spellings, and ticks rather than note values.
module HeadMusic::MIDI
  # Hi Wood Block: a neutral click for an unpitched sound whose instrument
  # names no GM percussion key, rather than one posing as a drum kit.
  DEFAULT_PERCUSSION_KEY = 76

  # +transposed:+ says the flow's pitches are written, so each sounds at its
  # written pitch plus its part's instrument's sounding transposition.
  def self.render(flow, transposed: false)
    Writer.new(flow, transposed: transposed).to_s
  end

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
