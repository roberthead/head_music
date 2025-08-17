# A module for music rudiments
module HeadMusic::Rudiment; end

# A pitch class is a set of pitches separated by octaves.
class HeadMusic::Rudiment::PitchClass < HeadMusic::Rudiment::Base
  include Comparable

  attr_reader :number, :spelling

  SHARP_SPELLINGS = %w[C C♯ D D♯ E F F♯ G G♯ A A♯ B].freeze
  FLAT_SPELLINGS = %w[C D♭ D E♭ E F G♭ G A♭ A B♭ B].freeze
  FLATTER_SPELLINGS = %w[C D♭ D E♭ F♭ F G♭ G A♭ A B♭ C♭].freeze
  INTEGER_NOTATION = %w[0 1 2 3 4 5 6 7 8 9 t e].freeze

  def self.get(identifier)
    @pitch_classes ||= {}
    if HeadMusic::Rudiment::Spelling.matching_string(identifier)
      spelling = HeadMusic::Rudiment::Spelling.get(identifier)
      number = spelling.pitch_class.to_i
    end
    number ||= identifier.to_i % 12
    @pitch_classes[number] ||= new(number)
  end

  class << self
    alias_method :[], :get
  end

  def initialize(pitch_class_or_midi_number)
    @number = pitch_class_or_midi_number.to_i % 12
  end

  def to_i
    number
  end

  def to_integer_notation
    INTEGER_NOTATION[number]
  end

  def sharp_spelling
    SHARP_SPELLINGS[number]
  end

  def flat_spelling
    FLAT_SPELLINGS[number]
  end

  def flatter_spelling
    FLATTER_SPELLINGS[number]
  end

  def smart_spelling(max_sharps_in_major_key_signature: 6)
    sharp_key = HeadMusic::Rudiment::KeySignature.get(sharp_spelling)
    return HeadMusic::Rudiment::Spelling.get(sharp_spelling) if sharp_key.num_sharps <= max_sharps_in_major_key_signature

    flat_key = HeadMusic::Rudiment::KeySignature.get(flat_spelling)
    return HeadMusic::Rudiment::Spelling.get(flat_spelling) if flat_key.num_sharps <= max_sharps_in_major_key_signature

    HeadMusic::Rudiment::Spelling.get(flatter_spelling)
  end

  # Pass in the number of semitones
  def +(other)
    HeadMusic::Rudiment::PitchClass.get(to_i + other.to_i)
  end

  # Pass in the number of semitones
  def -(other)
    HeadMusic::Rudiment::PitchClass.get(to_i - other.to_i)
  end

  def ==(other)
    to_i == other.to_i
  end
  alias_method :enharmonic?, :==

  def <=>(other)
    to_i <=> other.to_i
  end

  def intervals_to(other)
    delta = other.to_i - to_i
    inverse = delta.positive? ? delta - 12 : delta + 12
    [delta, inverse].sort_by(&:abs).map { |interval| HeadMusic::Rudiment::ChromaticInterval.get(interval) }
  end

  def smallest_interval_to(other)
    intervals_to(other).first
  end

  def white_key?
    [0, 2, 4, 5, 7, 9, 11].include?(number)
  end

  def black_key?
    !white_key?
  end

  private_class_method :new
end
