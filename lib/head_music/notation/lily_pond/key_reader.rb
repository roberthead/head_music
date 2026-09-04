# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Converts the pitch and mode tokens of a \key command into a key signature.
  class KeyReader
    TONIC_FRAGMENTS_BY_SEMITONES = {0 => "", 1 => "#", -1 => "b"}.freeze

    # The inverse of the writer's table, keyed by the mode command's name
    # without its backslash. Built lazily because the reader loads before
    # the writer.
    def self.scale_types_by_mode_command
      @scale_types_by_mode_command ||= KeyMapper::MODE_COMMANDS_BY_SCALE_TYPE
        .to_h { |scale_type, command| [command.delete_prefix("\\"), scale_type] }
        .freeze
    end

    def self.key_signature(pitch_token, mode_token)
      new(pitch_token, mode_token).key_signature
    end

    def initialize(pitch_token, mode_token)
      @pitch_token = pitch_token
      @mode_token = mode_token
    end

    def key_signature
      ensure_bare_pitch
      HeadMusic::Rudiment::KeySignature.get("#{tonic} #{scale_type}")
    end

    private

    attr_reader :pitch_token, :mode_token

    def ensure_bare_pitch
      return unless pitch_token.nil? || pitch_token.type != :note ||
        pitch_token.octave_marks || pitch_token.duration || pitch_token.multiplier

      raise error("\\key expects a pitch and a mode", pitch_token || mode_token)
    end

    def tonic
      semitones = PitchReader.alterations_by_suffix.fetch(pitch_token.suffix.to_s)
      fragment = TONIC_FRAGMENTS_BY_SEMITONES.fetch(semitones) do
        raise error(%(Cannot build a key signature on the double-altered tonic "#{pitch_token.lexeme}"), pitch_token)
      end
      "#{pitch_token.letter.upcase}#{fragment}"
    end

    def scale_type
      unless mode_token&.type == :command
        raise error("\\key expects a pitch and a mode", mode_token || pitch_token)
      end

      self.class.scale_types_by_mode_command.fetch(mode_token.lexeme) do
        raise error(%(Unrecognized mode "\\#{mode_token.lexeme}" in \\key command), mode_token)
      end
    end

    def error(message, token)
      ParseError.new(message, line_number: token&.line, column: token&.column, snippet: token&.lexeme)
    end
  end
end
