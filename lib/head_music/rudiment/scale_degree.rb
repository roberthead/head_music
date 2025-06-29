# A module for music rudiments
module HeadMusic::Rudiment; end

# A scale degree is a number indicating the ordinality of the spelling in the key.
# TODO: Rewrite to accept a tonal_center and a scale type.
class HeadMusic::Rudiment::ScaleDegree
  include Comparable

  NAME_FOR_DIATONIC_DEGREE = [nil, "tonic", "supertonic", "mediant", "subdominant", "dominant", "submediant"].freeze

  attr_reader :key_signature, :spelling

  delegate :scale, to: :key_signature
  delegate :scale_type, to: :scale

  def initialize(key_signature, spelling)
    @key_signature = key_signature
    @spelling = HeadMusic::Rudiment::Spelling.get(spelling)
  end

  def degree
    scale.letter_name_series_ascending.index(spelling.letter_name.to_s) + 1
  end

  def alteration
    spelling_alteration_semitones = spelling.alteration&.semitones || 0
    usual_sign_semitones = scale_degree_usual_spelling.alteration&.semitones || 0
    delta = spelling_alteration_semitones - usual_sign_semitones
    HeadMusic::Rudiment::Alteration.by(:semitones, delta) if delta != 0
  end

  def alteration_semitones
    alteration&.semitones || 0
  end

  def to_s
    "#{alteration}#{degree}"
  end

  def <=>(other)
    case other
    when HeadMusic::Rudiment::ScaleDegree
      [degree, alteration_semitones] <=> [other.degree, other.alteration_semitones]
    when Numeric
      degree <=> other
    when String
      to_s <=> other.to_s
    else
      # If we can't meaningfully compare, return nil (Ruby standard)
      nil
    end
  end

  def name_for_degree
    return unless scale_type.diatonic?

    NAME_FOR_DIATONIC_DEGREE[degree] ||
      ((scale_type.intervals.last == 1 || alteration == "#") ? "leading tone" : "subtonic")
  end

  private

  def scale_degree_usual_spelling
    HeadMusic::Rudiment::Spelling.get(scale.spellings[degree - 1])
  end
end
