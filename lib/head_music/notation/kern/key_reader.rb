# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads and writes the two kern interpretations about key: the signature
  # (*k[f#c#]) and the tonal designation (*D:, *b:, *d:dor). They are
  # independent in kern as they are in the timeline, which keeps the
  # signature's fifths and its tonal context apart.
  module KeyReader
    SHARPS = %w[f# c# g# d# a# e# b#].freeze
    FLATS = %w[b- e- a- d- g- c- f-].freeze
    SIGNATURE = /\A\*k\[(.*)\]\z/
    DESIGNATION = /\A\*([A-Ga-g])([#-]?):([a-z]*)\z/
    MODES = {
      "ion" => :ionian, "dor" => :dorian, "phr" => :phrygian, "lyd" => :lydian,
      "mix" => :mixolydian, "aeo" => :aeolian, "loc" => :locrian
    }.freeze
    TONIC_ALTERATIONS = {"" => "", "#" => "#", "-" => "b"}.freeze

    module_function

    def signature?(field)
      SIGNATURE.match?(field)
    end

    def designation?(field)
      DESIGNATION.match?(field)
    end

    # Sharps positive, flats negative. Only the standard orders are read: a
    # signature such as *k[f#b-] has no fifths count.
    def fifths(field, line_number: nil)
      accidentals = SIGNATURE.match(field)[1].scan(/[a-g][#-]+|./)
      return accidentals.length if accidentals == SHARPS.first(accidentals.length)
      return -accidentals.length if accidentals == FLATS.first(accidentals.length)

      raise UnsupportedFeatureError.new(
        "Non-standard key signatures are not supported (#{field})", line_number: line_number, snippet: field
      )
    end

    # Uppercase is major and lowercase minor, unless a mode follows the colon.
    def tonal_context(field, line_number: nil)
      _, letter, alteration, mode = *DESIGNATION.match(field)
      tonic = "#{letter.upcase}#{TONIC_ALTERATIONS.fetch(alteration)}"
      return HeadMusic::Rudiment::Key.get("#{tonic} #{(letter == letter.upcase) ? "major" : "minor"}") if mode.empty?

      mode_name = MODES.fetch(mode) do
        raise UnsupportedFeatureError.new(%(Unrecognized mode "#{mode}" in #{field}), line_number: line_number, snippet: field)
      end
      HeadMusic::Rudiment::Mode.get("#{tonic} #{mode_name}")
    end

    def signature_field(fifths)
      accidentals = fifths.negative? ? FLATS.first(-fifths) : SHARPS.first(fifths)
      "*k[#{accidentals.join}]"
    end

    # A key prints its tonic's case, and a mode its abbreviation. Nil for a
    # scale type kern cannot designate, such as harmonic minor.
    def designation_field(tonal_context)
      spelling = tonal_context.tonic_spelling
      letter = spelling.letter_name.to_s
      alteration = {1 => "#", -1 => "-"}[spelling.alteration&.semitones].to_s
      scale_type = tonal_context.scale_type.name.to_sym
      case scale_type
      when :major then "*#{letter.upcase}#{alteration}:"
      when :minor then "*#{letter.downcase}#{alteration}:"
      else
        mode = MODES.key(scale_type)
        "*#{letter.downcase}#{alteration}:#{mode}" if mode
      end
    end
  end
end
