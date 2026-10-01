# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads and writes the articulation, ornament, and sforzando signifiers
  # of a **kern note. The reading tables are the written ones turned
  # around, so whatever is written reads back as itself.
  module MarkCodes
    ARTICULATIONS = {"staccato" => "'", "staccatissimo" => "`", "accent" => "^", "tenuto" => "~", "marcato" => "^^"}.freeze
    # Humdrum keeps the older names: its mordent (M) is the upper Pralltriller
    # and its inverted mordent (W) the lower one, the reverse of the catalog.
    ORNAMENTS = {"trill" => "T", "mordent" => "W", "inverted_mordent" => "M", "turn" => "S"}.freeze
    # The other note dynamics have no token signifier, so they go in **dynam.
    NOTE_DYNAMICS = {"sfz" => "z"}.freeze
    # Kern's half-step forms, in lower case, read as the same ornament,
    # since the catalog does not hold the interval.
    HALF_STEP_ORNAMENTS = %w[trill mordent inverted_mordent].freeze

    # The heavy accent ^^ is read before the accent ^ it contains.
    ARTICULATIONS_BY_MARK = ARTICULATIONS.invert.sort_by { |mark, _key| -mark.length }.to_h.transform_values(&:to_sym).freeze
    ORNAMENTS_BY_MARK = {
      **ORNAMENTS.invert,
      **HALF_STEP_ORNAMENTS.to_h { |key| [ORNAMENTS.fetch(key).downcase, key] }
    }.transform_values(&:to_sym).freeze
    NOTE_DYNAMICS_BY_MARK = NOTE_DYNAMICS.invert.transform_values(&:to_sym).freeze

    module_function

    # Takes the marks out of +remaining+ and returns their catalog keys.
    def read!(remaining)
      {
        articulations: take!(remaining, ARTICULATIONS_BY_MARK),
        ornaments: take!(remaining, ORNAMENTS_BY_MARK),
        note_dynamic: take!(remaining, NOTE_DYNAMICS_BY_MARK).first
      }
    end

    def take!(remaining, keys_by_mark)
      keys_by_mark.filter_map { |mark, key| key if remaining.gsub!(mark, "") }.uniq.sort
    end

    def marks(voice_event)
      [
        *voice_event.articulations.map { |articulation| ARTICULATIONS.fetch(articulation.name_key) },
        *voice_event.ornaments.map { |ornament| ORNAMENTS.fetch(ornament.name_key) },
        NOTE_DYNAMICS[voice_event.note_dynamic&.name_key]
      ].join
    end
  end
end
