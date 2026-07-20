# A module for music rudiments
module HeadMusic::Rudiment; end

# Represents a musical key (major or minor)
class HeadMusic::Rudiment::Key < HeadMusic::Rudiment::QualifiedDiatonicContext
  QUALITIES = %i[major minor].freeze

  def self.default_qualifier
    :major
  end

  def self.valid_qualifiers
    QUALITIES
  end

  def self.invalid_qualifier_message
    "Quality must be :major or :minor"
  end

  alias_method :quality, :qualifier

  def major?
    quality == :major
  end

  def minor?
    quality == :minor
  end

  def relative
    if major?
      # Major to relative minor: down a minor third (3 semitones)
      relative_pitch = tonic_pitch + -3
      self.class.get("#{relative_pitch.spelling} minor")
    else
      # Minor to relative major: up a minor third (3 semitones)
      relative_pitch = tonic_pitch + 3
      self.class.get("#{relative_pitch.spelling} major")
    end
  end

  def parallel
    if major?
      self.class.get("#{tonic_spelling} minor")
    else
      self.class.get("#{tonic_spelling} major")
    end
  end
end
