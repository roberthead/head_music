# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Converts a key signature into the fifths/mode pair MusicXML's
  # <key> element needs.
  class KeyMapper
    # MusicXML's <mode> element only names these seven modes, so scale
    # types outside this set (harmonic minor, whole tone, etc.) cannot
    # be rendered as a <key> element and must raise instead.
    MODE_NAMES_BY_SCALE_TYPE = {
      "major" => "major",
      "ionian" => "major",
      "minor" => "minor",
      "aeolian" => "minor",
      "dorian" => "dorian",
      "phrygian" => "phrygian",
      "lydian" => "lydian",
      "mixolydian" => "mixolydian",
      "locrian" => "locrian"
    }.freeze

    # How far round the circle of fifths each mode's tonic sits from the
    # major tonic of the same signature: D dorian has C major's.
    TONIC_FIFTHS_BY_SCALE_TYPE = {
      "lydian" => -1, "major" => 0, "ionian" => 0, "mixolydian" => 1, "dorian" => 2,
      "minor" => 3, "aeolian" => 3, "phrygian" => 4, "locrian" => 5
    }.freeze

    LETTERS_BY_FIFTHS = %w[F C G D A E B].freeze

    # Returns the number of sharps (positive) or flats (negative) for the
    # <fifths> element. Theoretical keys with double accidentals (e.g. G#
    # major) count each double accidental twice, which is correct here.
    def self.fifths(key_signature)
      key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature)
      key_signature.num_sharps - key_signature.num_flats
    end

    # Returns the <mode> element value for a tonal context, or nil where there
    # is none.
    #
    # <mode> is optional in MusicXML, so a signature carrying no interpretation
    # renders as <fifths> alone rather than as an invented major.
    def self.mode(tonal_context)
      return nil if tonal_context.nil?

      identifier = tonal_context.is_a?(String) ? tonal_context : tonal_context.name
      scale_type = HeadMusic::Rudiment::KeySignature.get(identifier).scale_type
      MODE_NAMES_BY_SCALE_TYPE[scale_type.name.to_s] ||
        raise_render_error("Cannot render scale type #{scale_type} in a MusicXML <key> element")
    end

    # The Key or Mode a <fifths> and <mode> name, or nil for a mode MusicXML
    # names that the gem has no tonal context for, such as "none".
    def self.tonal_context(fifths, mode_name)
      scale_type = mode_name.to_s.strip.downcase
      return unless TONIC_FIFTHS_BY_SCALE_TYPE.key?(scale_type)

      tonic = tonic_name(fifths + TONIC_FIFTHS_BY_SCALE_TYPE.fetch(scale_type))
      klass = %w[major minor].include?(scale_type) ? HeadMusic::Rudiment::Key : HeadMusic::Rudiment::Mode
      tonic && klass.get("#{tonic} #{scale_type}")
    end

    # The spelling at a place on the circle of fifths, where C is 0, or nil
    # past a double accidental.
    def self.tonic_name(fifths)
      octaves, index = (fifths + 1).divmod(7)
      return if octaves.abs > 1

      LETTERS_BY_FIFTHS[index] + ((octaves == 1) ? "#" : "b") * octaves.abs
    end
    private_class_method :tonic_name

    def self.raise_render_error(message)
      raise HeadMusic::Notation::MusicXML::RenderError, message
    end
    private_class_method :raise_render_error
  end
end
