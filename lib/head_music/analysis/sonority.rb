# frozen_string_literal: true

# The Analysis module is used to identify pitch sets.
module HeadMusic::Analysis; end

# A Sonority describes a set of pitch class intervalic relationships.
# For example, a minor triad, or a major-minor seventh chord.
# The Sonority class is a factory for returning one of its subclasses.
class HeadMusic::Analysis::Sonority
  SIZES = %w[
    silence monad dyad trichord tetrachord pentachord hexachord heptachord octachord nonachord undecachord dodecachord
  ].freeze

  SONORITIES = %w[
    MajorTriad MinorTriad DiminishedTriad AugmentedTriad
  ].freeze

  attr_reader :pitch_set

  delegate :reduction, to: :pitch_set
  delegate :empty?, :empty_set?, to: :pitch_set
  delegate :monochord?, :monad, :dichord?, :dyad?, :trichord?, :tetrachord?, :pentachord?, :hexachord?, to: :pitch_set
  delegate :heptachord?, :octachord?, :nonachord?, :decachord?, :undecachord?, :dodecachord?, to: :pitch_set
  delegate :pitch_class_set, :pitch_class_set_size, to: :pitch_set

  # Returns a matching subclass
  def self.for(pitch_set)
    SONORITIES.each do |sonority_class_name|
      sonority = Object.const_get("HeadMusic::Analysis::#{sonority_class_name}").matching(pitch_set)
      next unless sonority
      return sonority
    end
    nil
  end

  def self.matching(pitch_set)
    sonority = new(pitch_set)
    sonority if sonority.match?
  end

  private_class_method :new

  def initialize(pitch_set)
    @pitch_set = pitch_set
  end

  def match?
    !inversion.nil?
  end

  def inversion
    return nil unless diatonic_intervals_above_bass_pitch.any?
    inversions.index(diatonic_intervals_above_bass_pitch)
  end

  def inversions
    return [] unless diatonic_intervals_above_bass_pitch.any?

    inversion = reduction
    reduction.pitches.map do
      inversion.diatonic_intervals_above_bass_pitch.tap do
        inversion = inversion.uninvert
      end
    end
  end

  def root_position
    inversions[inversion]
  end

  def consonant?
    pitch_set.reduction_diatonic_intervals.all?(&:consonant?) &&
      root_position.all?(&:consonant?)
  end

  def triad?
    is_a?(HeadMusic::Analysis::Triad)
  end

  def tertian?
    triad?
  end

  def secundal?
    false
  end

  def quartal?
    false
  end
  alias quintal? quartal?

  # @abstract Subclass is expected to implement #
  # @!method diatonic_intervals_above_bass_pitch
  #    return an array of diatonic intervals
end
