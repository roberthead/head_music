# frozen_string_literal: true

# A Sonority describes a set of pitch class intervalic relationships.
# For example, a minor triad, or a major-minor seventh chord.
# The Sonority class is a factory for returning one of its subclasses.
class HeadMusic::Sonority
  SONORITIES = {
    major_triad: %w[M3 P5],
    minor_triad: %w[m3 P5],
    diminished_triad: %w[m3 d5],
    augmented_triad: %w[M3 A5],
    major_minor_seventh_chord: %w[M3 P5 m7],
    major_major_seventh_chord: %w[M3 P5 M7],
    minor_minor_seventh_chord: %w[m3 P5 m7],
    minor_major_seventh_chord: %w[m3 P5 M7],
  }.freeze

  attr_reader :pitch_set

  delegate :reduction, to: :pitch_set
  delegate :empty?, :empty_set?, to: :pitch_set
  delegate :monochord?, :monad, :dichord?, :dyad?, :trichord?, :tetrachord?, :pentachord?, :hexachord?, to: :pitch_set
  delegate :heptachord?, :octachord?, :nonachord?, :decachord?, :undecachord?, :dodecachord?, to: :pitch_set
  delegate :pitch_class_set, :pitch_class_set_size, to: :pitch_set

  def initialize(pitch_set)
    @pitch_set = pitch_set
    identifier
  end

  def identifier
    return @identifier if defined?(@identifier)
    @identifier = SONORITIES.keys.detect do |key|
      inversions.map do |inversion|
        inversion.diatonic_intervals_above_bass_pitch.map(&:shorthand)
      end.include?(SONORITIES[key])
    end
  end

  def inversion
    @inversion ||= inversions.index do |inversion|
      SONORITIES[identifier] == inversion.diatonic_intervals_above_bass_pitch.map(&:shorthand)
    end
  end

  def inversions
    @inversions ||= begin
      inversion = reduction
      inversions = []
      inversion.pitches.length.times do |_i|
        inversions << inversion
        inversion = inversion.uninvert
      end
      inversions
    end
  end

  def root_position
    @root_position ||= inversions[inversion]
  end

  def consonant?
    @consonant ||=
      pitch_set.reduction_diatonic_intervals.all?(&:consonant?) &&
      root_position.diatonic_intervals_above_bass_pitch.all?(&:consonant?)
  end

  def triad?
    @triad ||= trichord? && tertian?
  end

  def seventh_chord?
    @seventh_chord ||= tetrachord? && tertian?
  end

  def tertian?
    @tertian ||= inversions.detect do |inversion|
      inversion.diatonic_intervals.all?(&:third?)
    end
  end

  def secundal?
    false
  end

  def quartal?
    false
  end
  alias quintal? quartal?

  def diatonic_intervals_above_bass_pitch
    return nil unless identifier

    @diatonic_intervals_above_bass_pitch ||=
      SONORITIES[identifier].map { |shorthand| HeadMusic::DiatonicInterval.get(shorthand) }
  end

  def ==(other)
    other = HeadMusic::PitchSet.new(other) if other.is_a?(Array)
    other = self.class.new(other) if other.is_a?(HeadMusic::PitchSet)
    identifier == other.identifier
  end
end
