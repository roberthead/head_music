# A module for music rudiments
module HeadMusic::Rudiment; end

# Shared behavior for diatonic contexts identified by a tonic spelling and a
# named qualifier -- a key's quality (major/minor) or a mode's name.
# Subclasses declare their valid qualifiers, default qualifier, and the
# message raised for an invalid qualifier, and implement #relative and #parallel.
class HeadMusic::Rudiment::QualifiedDiatonicContext < HeadMusic::Rudiment::DiatonicContext
  include HeadMusic::Named

  def self.get(identifier)
    return identifier if identifier.is_a?(self)

    @cache ||= {}
    tonic_spelling, qualifier = parse_identifier(identifier)
    hash_key = HeadMusic::Utilities::HashKey.for(identifier)
    @cache[hash_key] ||= new(tonic_spelling, qualifier)
  end

  def self.parse_identifier(identifier)
    tonic_spelling, qualifier = identifier.to_s.strip.split(/\s+/)
    [tonic_spelling, qualifier || default_qualifier.to_s]
  end

  def self.default_qualifier
    raise NotImplementedError, "Subclasses must implement .default_qualifier"
  end

  def self.valid_qualifiers
    raise NotImplementedError, "Subclasses must implement .valid_qualifiers"
  end

  def self.invalid_qualifier_message
    raise NotImplementedError, "Subclasses must implement .invalid_qualifier_message"
  end

  attr_reader :qualifier

  def initialize(tonic_spelling, qualifier = nil)
    super(tonic_spelling)
    @qualifier = (qualifier || self.class.default_qualifier).to_s.downcase.to_sym
    raise ArgumentError, self.class.invalid_qualifier_message unless self.class.valid_qualifiers.include?(@qualifier)
  end

  def scale_type
    @scale_type ||= HeadMusic::Rudiment::ScaleType.get(qualifier)
  end

  def name
    "#{tonic_spelling} #{qualifier}"
  end

  def to_s
    name
  end

  def ==(other)
    other = self.class.get(other)
    tonic_spelling == other.tonic_spelling && qualifier == other.qualifier
  end
end
