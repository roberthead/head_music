# Renders flows as Standard MIDI Files, and decodes them. MIDI holds a
# performance, not its notation: keys rather than spellings, and ticks rather
# than note values.
module HeadMusic::MIDI
  VELOCITIES = {"ppp" => 16, "pp" => 32, "p" => 48, "mp" => 64, "mf" => 80, "f" => 96, "ff" => 112, "fff" => 127}.freeze
  DEFAULT_LEVEL = "mf".freeze
  DEFAULT_VELOCITY = VELOCITIES.fetch(DEFAULT_LEVEL)
  VELOCITY_RANGE = (1..127)

  # Added to a note's velocity, together with any others it carries.
  ARTICULATION_BOOSTS = {"accent" => 16, "marcato" => 24}.freeze
  NOTE_DYNAMIC_BOOSTS = {"sf" => 24, "sfz" => 24, "rfz" => 16}.freeze

  # A note dynamic that strikes its note at a level of its own, as fp strikes
  # at f before leaving p in force.
  ATTACK_LEVELS = {"fp" => "f"}.freeze

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

  # Raised for a valid Standard MIDI File that holds no one piece to read.
  class UnsupportedFeatureError < ParseError; end

  # A subclass of the notation writers' error, so one rescue covers every writer.
  class RenderError < HeadMusic::Notation::RenderError; end
end

# Helper classes load in name order; they reference one another only at runtime.
Dir[File.join(__dir__, "midi", "*.rb")].sort.each { |file| require file }
