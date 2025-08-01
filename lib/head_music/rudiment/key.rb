# A module for music rudiments
module HeadMusic::Rudiment; end

# Represents a musical key (major or minor)
class HeadMusic::Rudiment::Key < HeadMusic::Rudiment::DiatonicContext
  include HeadMusic::Named

  QUALITIES = %i[major minor].freeze

  attr_reader :quality

  def self.get(identifier)
    return identifier if identifier.is_a?(HeadMusic::Rudiment::Key)

    @keys ||= {}
    tonic_spelling, quality_name = parse_identifier(identifier)
    hash_key = HeadMusic::Utilities::HashKey.for(identifier)
    @keys[hash_key] ||= new(tonic_spelling, quality_name)
  end

  def self.parse_identifier(identifier)
    identifier = identifier.to_s.strip
    parts = identifier.split(/\s+/)
    tonic_spelling = parts[0]
    quality_name = parts[1] || "major"
    [tonic_spelling, quality_name]
  end

  def initialize(tonic_spelling, quality = :major)
    super(tonic_spelling)
    @quality = quality.to_s.downcase.to_sym
    raise ArgumentError, "Quality must be :major or :minor" unless QUALITIES.include?(@quality)
  end

  def scale_type
    @scale_type ||= HeadMusic::Rudiment::ScaleType.get(quality)
  end

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

  def name
    "#{tonic_spelling} #{quality}"
  end

  def to_s
    name
  end

  def ==(other)
    other = self.class.get(other)
    tonic_spelling == other.tonic_spelling && quality == other.quality
  end
end
