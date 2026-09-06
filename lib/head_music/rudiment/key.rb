# A module for music rudiments
module HeadMusic::Rudiment; end

# Represents a musical key (major or minor)
class HeadMusic::Rudiment::Key < HeadMusic::Rudiment::QualifiedDiatonicContext
  QUALITIES = %i[major minor].freeze

  # The conventional reading of a signature that carries no interpretation of
  # its own: the major key with that many sharps or flats.
  #
  # A signature underdetermines its key -- two sharps is D major, B minor,
  # E dorian, or A mixolydian -- so this is a fallback for the consumers that
  # cannot proceed without a tonic (LilyPond's \key, and the Diatonic
  # guideline), not a claim about the music.
  #
  # Signatures themselves are unbounded: a theoretical key such as G♯ major
  # counts each double accidental twice and reaches eight. The table stops at
  # seven, because past that there is no conventional major key to name.
  MAJOR_KEY_NAMES_BY_FIFTHS = {
    -7 => "C♭", -6 => "G♭", -5 => "D♭", -4 => "A♭", -3 => "E♭", -2 => "B♭", -1 => "F",
    0 => "C",
    1 => "G", 2 => "D", 3 => "A", 4 => "E", 5 => "B", 6 => "F♯", 7 => "C♯"
  }.freeze

  # @param fifths [Integer] sharps as positive, flats as negative
  # @return [HeadMusic::Rudiment::Key] the major key with that signature
  # @raise [ArgumentError] for a signature outside -7..+7, which names no
  #   conventional major key
  def self.for_fifths(fifths)
    tonic = MAJOR_KEY_NAMES_BY_FIFTHS[fifths]
    raise ArgumentError, "no conventional key for a signature of #{fifths} fifths" if tonic.nil?

    get("#{tonic} major")
  end

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
