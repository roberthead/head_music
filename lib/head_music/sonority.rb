# frozen_string_literal: true

require 'head_music/sonority/major_triad'
require 'head_music/sonority/minor_triad'
require 'head_music/sonority/diminished_triad'

# A sonority describes a combination of pitch class intervalic relationships.
# For example, a minor triad, or a major-minor seventh chord.
# The Sonority class is a factory for returning one of its subclasses.
class HeadMusic::Sonority
  SIZES = %w[
    silence monad dyad trichord tetrachord pentachord hexachord heptachord octachord nonachord undecachord dodecachord
  ].freeze

  SONORITIES = [
    # Dyad,
    MajorTriad, MinorTriad, DiminishedTriad, # AugmentedTriad,
    # SuspendedChord,
    # MajorMinorSeventhChord, MajorMajorSeventhChord, MinorMinorSeventhChord, MinorMajorSeventhChord,
    # HalfDiminishedSeventhChord, FullyDiminishedSeventhChord,
  ].freeze

  attr_reader :pitch_set

  delegate :reduction, to: :pitch_set
  delegate :empty?, :empty_set?, to: :pitch_set
  delegate :monochord?, :monad, :dichord?, :dyad?, :trichord?, :tetrachord?, :pentachord?, :hexachord?, to: :pitch_set
  delegate :heptachord?, :octachord?, :nonachord?, :decachord?, :undecachord?, :dodecachord?, to: :pitch_set
  delegate :pitch_class_set_size, to: :pitch_set

  # Returns a matching subclass
  def self.for(pitch_set)
    SONORITIES.each do |sonority_class|
      sonority = sonority_class.matching(pitch_set)
      next unless sonority
      return sonority
    end
    nil
  end

  def self.matching(pitch_set)
    sonority = new(pitch_set)
    sonority if sonority.match?
  end

  def initialize(pitch_set)
    @pitch_set = pitch_set
  end

  def match?
    !inversion.nil?
  end

  def inversion
    return nil unless diatonic_intervals_above_bass_pitch.any?

    inversion = reduction
    reduction.pitches.length.times do |inversion_count|
      return inversion_count if inversion.diatonic_intervals_above_bass_pitch == diatonic_intervals_above_bass_pitch
      inversion = inversion.uninvert
    end
    nil
  end

  def triad?
    false
  end

  def consonant_triad?
    false
  end

  def tertian?
    false
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
