# A module for music rudiments
module HeadMusic::Rudiment; end

# Represents a key signature (traditionally associated with a key)
# This class maintains backward compatibility while delegating to Key/Mode internally
class HeadMusic::Rudiment::KeySignature < HeadMusic::Rudiment::Base
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
  end

  def spellings
    pitches.map(&:spelling).uniq
  end

  def sharps
    altered_spellings(:sharp?, ORDERED_LETTER_NAMES_OF_SHARPS)
  end

  def double_sharps
    altered_spellings(:double_sharp?, ORDERED_LETTER_NAMES_OF_SHARPS)
  end

  def flats
    altered_spellings(:flat?, ORDERED_LETTER_NAMES_OF_FLATS)
  end

  def double_flats
    altered_spellings(:double_flat?, ORDERED_LETTER_NAMES_OF_FLATS)
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
    return pluralize(sharps.length, "sharp") if sharps.any?
    return pluralize(flats.length, "flat") if flats.any?

    "no sharps or flats"
  end

  def enharmonic_equivalent?(other)
    enharmonic_equivalence.enharmonic_equivalent?(other)
  end

  private

  def altered_spellings(predicate, letter_name_order)
    spellings.select(&predicate).sort_by do |spelling|
      letter_name_order.index(spelling.letter_name.to_s)
    end
  end

  def pluralize(count, noun)
    (count == 1) ? "1 #{noun}" : "#{count} #{noun}s"
  end

  def enharmonic_equivalence
    @enharmonic_equivalence ||= HeadMusic::Rudiment::KeySignature::EnharmonicEquivalence.get(self)
  end
end
