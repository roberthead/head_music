# A module for music rudiments
module HeadMusic::Rudiment; end

# Represents a key signature (traditionally associated with a key)
# This class maintains backward compatibility while delegating to Key/Mode internally
class HeadMusic::Rudiment::KeySignature < HeadMusic::Rudiment::Base
  attr_reader :tonal_context

  ORDERED_LETTER_NAMES_OF_SHARPS = %w[F C G D A E B].freeze
  ORDERED_LETTER_NAMES_OF_FLATS = ORDERED_LETTER_NAMES_OF_SHARPS.reverse.freeze

  def self.default
    @default ||= new("C", :major)
  end

  def self.get(identifier)
    return identifier if identifier.is_a?(HeadMusic::Rudiment::KeySignature)

    @key_signatures ||= {}

    if identifier.is_a?(String)
      tonic_spelling, scale_type_name = identifier.strip.split(/\s/)
      hash_key = HeadMusic::Utilities::HashKey.for(identifier.gsub(/#|♯/, " sharp").gsub(/(\w)[b♭]/, '\\1 flat'))
      @key_signatures[hash_key] ||= new(tonic_spelling, scale_type_name)
    elsif identifier.is_a?(HeadMusic::Rudiment::DiatonicContext)
      identifier.key_signature
    end
  end

  def self.from_tonal_context(tonal_context)
    new_from_context(tonal_context)
  end

  def self.from_scale(scale)
    # Find a key or mode that uses this scale
    tonic = scale.root_pitch.spelling
    scale_type = scale.scale_type
    new(tonic, scale_type)
  end

  attr_reader :tonic_spelling, :scale_type, :scale

  delegate :pitch_class, to: :tonic_spelling, prefix: :tonic
  delegate :pitches, :pitch_classes, to: :scale
  delegate :to_s, to: :name

  def initialize(tonic_spelling, scale_type = nil)
    @tonic_spelling = HeadMusic::Rudiment::Spelling.get(tonic_spelling)
    @scale_type = HeadMusic::Rudiment::ScaleType.get(scale_type) if scale_type
    @scale_type ||= HeadMusic::Rudiment::ScaleType.default
    @scale_type = @scale_type.parent || @scale_type
    @scale = HeadMusic::Rudiment::Scale.get(@tonic_spelling, @scale_type)

    # Create appropriate tonal context
    scale_type_str = scale_type.to_s.downcase if scale_type

    @tonal_context = if %w[major minor].include?(scale_type_str)
      HeadMusic::Rudiment::Key.get("#{tonic_spelling} #{scale_type}")
    elsif scale_type
      HeadMusic::Rudiment::Mode.get("#{tonic_spelling} #{scale_type}")
    else
      HeadMusic::Rudiment::Key.get("#{tonic_spelling} major")
    end
  rescue ArgumentError
    # Fall back to creating a major key if mode is not recognized
    @tonal_context = HeadMusic::Rudiment::Key.get("#{tonic_spelling} major")
  end

  def self.new_from_context(context)
    instance = allocate
    instance.instance_variable_set(:@tonal_context, context)
    instance
  end

  def spellings
    pitches.map(&:spelling).uniq
  end

  def sharps
    spellings.select(&:sharp?).sort_by do |spelling|
      ORDERED_LETTER_NAMES_OF_SHARPS.index(spelling.letter_name.to_s)
    end
  end

  def double_sharps
    spellings.select(&:double_sharp?).sort_by do |spelling|
      ORDERED_LETTER_NAMES_OF_SHARPS.index(spelling.letter_name.to_s)
    end
  end

  def flats
    spellings.select(&:flat?).sort_by do |spelling|
      ORDERED_LETTER_NAMES_OF_FLATS.index(spelling.letter_name.to_s)
    end
  end

  def double_flats
    spellings.select(&:double_flat?).sort_by do |spelling|
      ORDERED_LETTER_NAMES_OF_FLATS.index(spelling.letter_name.to_s)
    end
  end

  def num_sharps
    sharps.length + double_sharps.length * 2
  end

  def num_flats
    flats.length + double_flats.length * 2
  end

  def num_alterations
    num_sharps + num_flats
  end

  def alterations
    flats.any? ? (double_flats + flats) : (double_sharps + sharps)
  end

  alias_method :sharps_and_flats, :alterations
  alias_method :accidentals, :alterations

  def name
    [tonic_spelling, scale_type].join(" ")
  end

  def ==(other)
    alterations == self.class.get(other).alterations
  end

  def to_s
    if sharps.any?
      (sharps.length == 1) ? "1 sharp" : "#{sharps.length} sharps"
    elsif flats.any?
      (flats.length == 1) ? "1 flat" : "#{flats.length} flats"
    else
      "no sharps or flats"
    end
  end

  def enharmonic_equivalent?(other)
    enharmonic_equivalence.enharmonic_equivalent?(other)
  end

  private

  def enharmonic_equivalence
    @enharmonic_equivalence ||= HeadMusic::Rudiment::KeySignature::EnharmonicEquivalence.get(self)
  end
end
