# frozen_string_literal: true

# Represents a key signature.
class HeadMusic::KeySignature
  attr_reader :tonic_spelling
  attr_reader :scale_type
  attr_reader :scale

  SHARPS = %w[F♯ C♯ G♯ D♯ A♯ E♯ B♯].freeze
  FLATS = %w[B♭ E♭ A♭ D♭ G♭ C♭ F♭].freeze

  def self.default
    @default ||= new('C', :major)
  end

  def self.get(identifier)
    return identifier if identifier.is_a?(HeadMusic::KeySignature)
    @key_signatures ||= {}
    tonic_spelling, scale_type_name = identifier.strip.split(/\s/)
    hash_key = HeadMusic::Utilities::HashKey.for(identifier.gsub(/#|♯/, ' sharp').gsub(/(\w)[b♭]/, '\\1 flat'))
    @key_signatures[hash_key] ||= new(tonic_spelling, scale_type_name)
  end

  delegate :pitch_class, to: :tonic_spelling, prefix: :tonic
  delegate :to_s, to: :name
  delegate :pitches, to: :scale

  def initialize(tonic_spelling, scale_type = nil)
    @tonic_spelling = HeadMusic::Spelling.get(tonic_spelling)
    @scale_type = HeadMusic::ScaleType.get(scale_type) if scale_type
    @scale_type ||= HeadMusic::ScaleType.default
    @scale_type = @scale_type.parent || @scale_type
    @scale = HeadMusic::Scale.get(@tonic_spelling, @scale_type)
  end

  def spellings
    pitches.map(&:spelling).uniq
  end

  def sharps
    spellings.select(&:sharp?).sort_by { |sharp| SHARPS.index(sharp.to_s) }
  end

  def flats
    spellings.select(&:flat?).sort_by { |flat| FLATS.index(flat.to_s) }
  end

  def num_sharps
    sharps.length
  end

  def num_flats
    flats.length
  end

  def signs
    flats.any? ? flats : sharps
  end

  alias sharps_and_flats signs
  alias accidentals signs

  def name
    [tonic_spelling, scale_type].join(' ')
  end

  def ==(other)
    signs == self.class.get(other).signs
  end

  def to_s
    if sharps.any?
      sharps.length == 1 ? '1 sharp' : "#{sharps.length} sharps"
    elsif flats.any?
      flats.length == 1 ? '1 flat' : "#{flats.length} flats"
    else
      'no sharps or flats'
    end
  end

  def enharmonic_equivalent?(other)
    other = KeySignature.get(other)
    enharmonic_equivalence.equivalent?(other)
  end

  private

  def enharmonic_equivalence
    @enharmonic_equivalence ||= EnharmonicEquivalence.get(self)
  end

  # Key signatures are enharmonic when all pitch classes in one are respellings of the pitch classes in the other.
  class EnharmonicEquivalence
    def self.get(key_signature)
      key_signature = HeadMusic::KeySignature.get(key_signature)
      @enharmonic_equivalences ||= {}
      @enharmonic_equivalences[key_signature.to_s] ||= new(key_signature)
    end

    attr_reader :key_signature

    def initialize(key_signature)
      @key_signature = HeadMusic::KeySignature.get(key_signature)
    end

    def enharmonic_equivalent?(other)
      other = HeadMusic::KeySignature.get(other)
      (key_signature.signs | other.signs).map(&:to_s).uniq.length == 12
    end

    alias enharmonic? enharmonic_equivalent?
    alias equivalent? enharmonic_equivalent?

    private_class_method :new
  end
end
