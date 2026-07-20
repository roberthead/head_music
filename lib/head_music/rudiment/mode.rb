# A module for music rudiments
module HeadMusic::Rudiment; end

# Represents a musical mode (church modes)
class HeadMusic::Rudiment::Mode < HeadMusic::Rudiment::QualifiedDiatonicContext
  MODES = %i[ionian dorian phrygian lydian mixolydian aeolian locrian].freeze

  def self.default_qualifier
    :ionian
  end

  def self.valid_qualifiers
    MODES
  end

  def self.invalid_qualifier_message
    "Mode must be one of: #{MODES.join(", ")}"
  end

  alias_method :mode_name, :qualifier

  def relative_major
    case mode_name
    when :ionian
      return HeadMusic::Rudiment::Key.get("#{tonic_spelling} major")
    when :dorian
      relative_pitch = tonic_pitch + -2
    when :phrygian
      relative_pitch = tonic_pitch + -4
    when :lydian
      relative_pitch = tonic_pitch + -5
    when :mixolydian
      relative_pitch = tonic_pitch + -7
    when :aeolian
      relative_pitch = tonic_pitch + -9
    when :locrian
      relative_pitch = tonic_pitch + -11
    end

    HeadMusic::Rudiment::Key.get("#{relative_pitch.spelling} major")
  end

  def relative
    relative_major
  end

  def parallel
    # Return the parallel major or minor key
    case mode_name
    when :ionian
      HeadMusic::Rudiment::Key.get("#{tonic_spelling} major")
    when :aeolian
      HeadMusic::Rudiment::Key.get("#{tonic_spelling} minor")
    when :dorian, :phrygian
      HeadMusic::Rudiment::Key.get("#{tonic_spelling} minor")
    when :lydian, :mixolydian
      HeadMusic::Rudiment::Key.get("#{tonic_spelling} major")
    when :locrian
      HeadMusic::Rudiment::Key.get("#{tonic_spelling} minor")
    end
  end
end
