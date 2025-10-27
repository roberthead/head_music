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

  DEFAULT_ROOT = "C4"

  # Factory method to get a sonority by identifier
  # Returns a Sonority with pitches starting at the default root (C4)
  #
  # @param identifier [Symbol, String] the sonority identifier (e.g., :major_triad)
  # @param root [String] the root pitch (default: "C4")
  # @param inversion [Integer] the inversion number (default: 0 for root position)
  # @return [Sonority, nil] the sonority object, or nil if identifier not found
  def self.get(identifier, root: DEFAULT_ROOT, inversion: 0)
    identifier = identifier.to_sym
    return nil unless SONORITIES.key?(identifier)

    root_pitch = HeadMusic::Rudiment::Pitch.get(root)
    interval_shorthands = SONORITIES[identifier]

    # Build pitches: root + intervals above root
    pitches = [root_pitch] + interval_shorthands.map do |shorthand|
      interval = HeadMusic::Analysis::DiatonicInterval.get(shorthand)
      interval.above(root_pitch)
    end

    pitch_collection = HeadMusic::Analysis::PitchCollection.new(pitches)

    # Apply inversions if requested
    inversion.times do
      pitch_collection = pitch_collection.invert
    end

    new(pitch_collection)
  end

  # Returns all available sonority identifiers
  # @return [Array<Symbol>] array of sonority identifiers
  def self.identifiers
    SONORITIES.keys
  end

  attr_reader :pitch_collection

  delegate :reduction, to: :pitch_collection
  delegate :empty?, :empty_set?, to: :pitch_collection
  delegate :monochord?, :monad, :dichord?, :dyad?, :trichord?, :tetrachord?, :pentachord?, :hexachord?, to: :pitch_collection
  delegate :heptachord?, :octachord?, :nonachord?, :decachord?, :undecachord?, :dodecachord?, to: :pitch_collection
  delegate :pitch_class_set, :pitch_class_set_size, to: :pitch_collection
  delegate :scale_degrees_above_bass_pitch, to: :pitch_collection

  def initialize(pitch_collection)
    @pitch_collection = pitch_collection
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
      pitch_collection.reduction_diatonic_intervals.all?(&:consonant?) &&
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
    other = HeadMusic::Analysis::PitchCollection.new(other) if other.is_a?(Array)
    other = self.class.new(other) if other.is_a?(HeadMusic::Analysis::PitchCollection)
    identifier == other.identifier
  end
end
