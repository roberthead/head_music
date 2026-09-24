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
    case identifier
    when self then identifier
    when String then fetch_or_register(HeadMusic::Utilities::HashKey.for(identifier), *identifier.strip.split(/\s/).first(2))
    when HeadMusic::Rudiment::DiatonicContext then identifier.key_signature
    end
  end

  def self.from_scale(scale)
    new(scale.root_pitch.spelling, scale.scale_type)
  end

  attr_reader :tonic_spelling, :scale_type, :scale

  delegate :pitch_class, to: :tonic_spelling, prefix: :tonic
  delegate :pitches, :pitch_classes, to: :scale

  def initialize(tonic_spelling, scale_type = nil)
    @tonic_spelling = HeadMusic::Rudiment::Spelling.get(tonic_spelling)
    scale_type = HeadMusic::Rudiment::ScaleType.get(scale_type || :major)
    @scale_type = scale_type.parent || scale_type
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
    count, noun = sharps.any? ? [sharps.length, "sharp"] : [flats.length, "flat"]
    count.zero? ? "no sharps or flats" : "#{count} #{noun.pluralize(count)}"
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

  def enharmonic_equivalence
    @enharmonic_equivalence ||= HeadMusic::Rudiment::KeySignature::EnharmonicEquivalence.get(self)
  end
end
