# A module for musical analysis
module HeadMusic::Analysis; end

# Classifies a PitchCollection as a tertian chord: whether it is a triad,
# seventh, or extended chord; its triad quality (major/minor/diminished/
# augmented); and its inversion. "Tertian" means the pitches, once reduced to
# within an octave and rotated, stack in thirds.
class HeadMusic::Analysis::ChordAnalysis
  # Scale-degree signatures (above the bass) of each tertian chord size, used
  # to recognize a stack of thirds in any rotation.
  TERTIAN_SONORITIES = {
    implied_triad: [3],
    triad: [3, 5],
    seventh_chord: [3, 5, 7],
    ninth_chord: [2, 3, 5, 7],
    eleventh_chord: [2, 3, 4, 5, 7],
    thirteenth_chord: [2, 3, 4, 5, 6, 7] # a.k.a. diatonic scale
  }.freeze

  # The interval-shorthand pairs (bass-to-third, third-to-fifth) that spell each
  # triad quality, in every inversion.
  TRIAD_PATTERNS = {
    major: [%w[M3 m3], %w[m3 P4], %w[P4 M3]],
    minor: [%w[m3 M3], %w[M3 P4], %w[P4 m3]],
    diminished: [%w[m3 m3], %w[m3 A4], %w[A4 m3]],
    augmented: [%w[M3 M3], %w[M3 d4], %w[d4 M3]]
  }.freeze

  attr_reader :collection

  def initialize(collection)
    @collection = collection
  end

  def triad?
    collection.trichord? && tertian?
  end

  def consonant_triad?
    major_triad? || minor_triad?
  end

  def major_triad?
    triad_type?(:major)
  end

  def minor_triad?
    triad_type?(:minor)
  end

  def diminished_triad?
    triad_type?(:diminished)
  end

  def augmented_triad?
    triad_type?(:augmented)
  end

  def root_position_triad?
    collection.trichord? && stacked_in_thirds?(collection.reduction)
  end

  def first_inversion_triad?
    collection.trichord? && stacked_in_thirds?(collection.reduction.uninvert)
  end

  def second_inversion_triad?
    collection.trichord? && stacked_in_thirds?(collection.reduction.invert)
  end

  def seventh_chord?
    collection.tetrachord? && tertian?
  end

  def root_position_seventh_chord?
    collection.tetrachord? && stacked_in_thirds?(collection.reduction)
  end

  def first_inversion_seventh_chord?
    collection.tetrachord? && stacked_in_thirds?(collection.reduction.uninvert)
  end

  def second_inversion_seventh_chord?
    collection.tetrachord? && stacked_in_thirds?(collection.reduction.uninvert.uninvert)
  end

  def third_inversion_seventh_chord?
    collection.tetrachord? && stacked_in_thirds?(collection.reduction.invert)
  end

  def ninth_chord?
    collection.pentachord? && tertian?
  end

  def eleventh_chord?
    collection.hexachord? && tertian?
  end

  def thirteenth_chord?
    collection.heptachord? && tertian?
  end

  def tertian?
    return false unless collection.diatonic_intervals.any?

    inversion = collection.reduction
    collection.pitches.length.times do
      return true if TERTIAN_SONORITIES.value?(inversion.scale_degrees_above_bass_pitch)
      inversion = inversion.invert
    end
    false
  end

  private

  def triad_type?(type)
    TRIAD_PATTERNS[type].include?(collection.reduction_diatonic_intervals.map(&:shorthand))
  end

  def stacked_in_thirds?(reduced_collection)
    reduced_collection.diatonic_intervals.all?(&:third?)
  end
end
