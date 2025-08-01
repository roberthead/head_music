# A module for music rudiments
module HeadMusic::Rudiment; end

# Represents a musical mode (church modes)
class HeadMusic::Rudiment::Mode < HeadMusic::Rudiment::DiatonicContext
  include HeadMusic::Named

  MODES = %i[ionian dorian phrygian lydian mixolydian aeolian locrian].freeze

  attr_reader :mode_name

  def self.get(identifier)
    return identifier if identifier.is_a?(HeadMusic::Rudiment::Mode)

    @modes ||= {}
    tonic_spelling, mode_name = parse_identifier(identifier)
    hash_key = HeadMusic::Utilities::HashKey.for(identifier)
    @modes[hash_key] ||= new(tonic_spelling, mode_name)
  end

  def self.parse_identifier(identifier)
    identifier = identifier.to_s.strip
    parts = identifier.split(/\s+/)
    tonic_spelling = parts[0]
    mode_name = parts[1] || "ionian"
    [tonic_spelling, mode_name]
  end

  def initialize(tonic_spelling, mode_name = :ionian)
    super(tonic_spelling)
    @mode_name = mode_name.to_s.downcase.to_sym
    raise ArgumentError, "Mode must be one of: #{MODES.join(", ")}" unless MODES.include?(@mode_name)
  end

  def scale_type
    @scale_type ||= HeadMusic::Rudiment::ScaleType.get(mode_name)
  end

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

  def name
    "#{tonic_spelling} #{mode_name}"
  end

  def to_s
    name
  end

  def ==(other)
    other = self.class.get(other)
    tonic_spelling == other.tonic_spelling && mode_name == other.mode_name
  end
end
