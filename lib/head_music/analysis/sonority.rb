# A module for musical analysis
module HeadMusic::Analysis; end

# A Sonority describes a set of pitch class intervalic relationships.
# For example, a minor triad, or a major-minor seventh chord.
# The Sonority class is a factory for returning one of its subclasses.
class HeadMusic::Analysis::Sonority
  SONORITIES = {
    major_triad: %w[M3 P5],
    minor_triad: %w[m3 P5],
    diminished_triad: %w[m3 d5],
    augmented_triad: %w[M3 A5],
    major_minor_seventh_chord: %w[M3 P5 m7],
    major_major_seventh_chord: %w[M3 P5 M7],
    minor_minor_seventh_chord: %w[m3 P5 m7],
    minor_major_seventh_chord: %w[m3 P5 M7],
    half_diminished_seventh_chord: %w[m3 d5 m7],
    diminished_seventh_chord: %w[m3 d5 d7],
    dominant_ninth_chord: %w[M2 M3 P5 m7],
    dominant_minor_ninth_chord: %w[m2 M3 P5 m7],
    minor_ninth_chord: %w[M2 m3 P5 m7],
    major_ninth_chord: %w[M2 M3 P5 M7],
    six_nine_chord: %w[M2 M3 P5 M6],
    minor_six_nine_chord: %w[M2 m3 P5 M6],
    suspended_four_chord: %w[P4 P5],
    suspended_two_chord: %w[M2 P5],
    quartal_chord: %w[P4 m7]
  }.freeze

  attr_reader :pitch_set

  delegate :reduction, to: :pitch_set
  delegate :empty?, :empty_set?, to: :pitch_set
  delegate :monochord?, :monad, :dichord?, :dyad?, :trichord?, :tetrachord?, :pentachord?, :hexachord?, to: :pitch_set
  delegate :heptachord?, :octachord?, :nonachord?, :decachord?, :undecachord?, :dodecachord?, to: :pitch_set
  delegate :pitch_class_set, :pitch_class_set_size, to: :pitch_set
  delegate :scale_degrees_above_bass_pitch, to: :pitch_set

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
      inversion.diatonic_intervals.count(&:third?).to_f / inversion.diatonic_intervals.length > 0.5 ||
        (scale_degrees_above_bass_pitch && [3, 5, 7]).length == 3
    end
  end

  def secundal?
    @secundal ||= inversions.detect do |inversion|
      inversion.diatonic_intervals.count(&:second?).to_f / inversion.diatonic_intervals.length > 0.5
    end
  end

  def quartal?
    @quartal ||= inversions.detect do |inversion|
      inversion.diatonic_intervals.count do |interval|
        interval.fourth? || interval.fifth?
      end.to_f / inversion.diatonic_intervals.length > 0.5
    end
  end
  alias_method :quintal?, :quartal?

  def diatonic_intervals_above_bass_pitch
    return [] unless identifier

    @diatonic_intervals_above_bass_pitch ||=
      SONORITIES[identifier].map { |shorthand| HeadMusic::Analysis::DiatonicInterval.get(shorthand) }
  end

  def ==(other)
    other = HeadMusic::Analysis::PitchSet.new(other) if other.is_a?(Array)
    other = self.class.new(other) if other.is_a?(HeadMusic::Analysis::PitchSet)
    identifier == other.identifier
  end
end
