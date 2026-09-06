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

    def self.raise_render_error(message)
      raise HeadMusic::Notation::MusicXML::RenderError, message
    end
    private_class_method :raise_render_error
  end
end
