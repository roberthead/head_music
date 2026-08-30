# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Converts a key signature into a LilyPond \key command.
  class KeyMapper
    # LilyPond's \key command names these nine modes, so scale types
    # outside this set (harmonic minor, whole tone, etc.) cannot be
    # rendered as a \key command and must raise instead.
    MODE_COMMANDS_BY_SCALE_TYPE = {
      "major" => "\\major",
      "ionian" => "\\ionian",
      "minor" => "\\minor",
      "aeolian" => "\\aeolian",
      "dorian" => "\\dorian",
      "phrygian" => "\\phrygian",
      "lydian" => "\\lydian",
      "mixolydian" => "\\mixolydian",
      "locrian" => "\\locrian"
    }.freeze

    def self.token(key_signature)
      key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature)
      "\\key #{tonic(key_signature)} #{mode(key_signature)}"
    end

    def self.tonic(key_signature)
      spelling = key_signature.tonic_spelling
      spelling.letter_name.to_s.downcase + PitchWriter.alteration_suffix(spelling.alteration&.semitones)
    end
    private_class_method :tonic

    def self.mode(key_signature)
      MODE_COMMANDS_BY_SCALE_TYPE.fetch(key_signature.scale_type.name.to_s) do
        raise RenderError, "cannot render scale type #{key_signature.scale_type} in a LilyPond \\key command"
      end
    end
    private_class_method :mode
  end
end
