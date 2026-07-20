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

  # Semitones from a mode's tonic down to its relative major tonic.
  # Ionian is omitted because its own tonic spelling is the relative major.
  RELATIVE_MAJOR_SEMITONES_BELOW_TONIC = {
    dorian: -2, phrygian: -4, lydian: -5,
    mixolydian: -7, aeolian: -9, locrian: -11
  }.freeze

  # The major or minor quality of each mode's parallel key.
  PARALLEL_QUALITIES = {
    ionian: :major, dorian: :minor, phrygian: :minor, lydian: :major,
    mixolydian: :major, aeolian: :minor, locrian: :minor
  }.freeze

  def relative_major
    HeadMusic::Rudiment::Key.get("#{relative_major_tonic_spelling} major")
  end

  def relative
    relative_major
  end

  def parallel
    quality = PARALLEL_QUALITIES[mode_name]
    return unless quality

    HeadMusic::Rudiment::Key.get("#{tonic_spelling} #{quality}")
  end

  private

  def relative_major_tonic_spelling
    return tonic_spelling if mode_name == :ionian

    offset = RELATIVE_MAJOR_SEMITONES_BELOW_TONIC[mode_name]
    relative_pitch = tonic_pitch + offset if offset
    # An unrecognized mode leaves relative_pitch nil, raising NoMethodError (preserved behavior).
    relative_pitch.spelling
  end
end
