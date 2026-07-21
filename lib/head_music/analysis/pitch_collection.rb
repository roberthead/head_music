# A module for musical analysis
module HeadMusic::Analysis; end

# A PitchCollection is a collection of one or more pitches with specific registers.
# In music theory, "pitch collection" refers to an ordered or unordered group of actual pitches,
# as distinct from a "pitch-class set" which abstracts away register and octave equivalence.
# See also: PitchClassSet
class HeadMusic::Analysis::PitchCollection
  attr_reader :pitches

  delegate :diatonic_intervals, to: :reduction, prefix: true
  delegate :empty?, :empty_set?, to: :pitch_class_set
  delegate :monochord?, :monad?, :dichord?, :dyad?, to: :pitch_class_set
  delegate :trichord?, :tetrachord?, :pentachord?, :hexachord?, to: :pitch_class_set
  delegate :heptachord?, :octachord?, :nonachord?, :decachord?, :undecachord?, :dodecachord?, to: :pitch_class_set
  delegate :size, to: :pitch_class_set, prefix: true

  # Tertian chord classification (triad/seventh/extended, quality, inversion).
  delegate(
    :triad?, :consonant_triad?,
    :major_triad?, :minor_triad?, :diminished_triad?, :augmented_triad?,
    :root_position_triad?, :first_inversion_triad?, :second_inversion_triad?,
    :seventh_chord?, :root_position_seventh_chord?, :first_inversion_seventh_chord?,
    :second_inversion_seventh_chord?, :third_inversion_seventh_chord?,
    :ninth_chord?, :eleventh_chord?, :thirteenth_chord?, :tertian?,
    to: :chord_analysis
  )

  def initialize(pitches)
    @pitches = pitches.map { |pitch| HeadMusic::Rudiment::Pitch.get(pitch) }.sort.uniq
  end

  def pitch_classes
    @pitch_classes ||= reduction_pitches.map(&:pitch_class).uniq
  end

  def pitch_class_set
    @pitch_class_set ||= HeadMusic::Analysis::PitchClassSet.new(pitch_classes)
  end

  def reduction
    @reduction ||= HeadMusic::Analysis::PitchCollection.new(reduction_pitches)
  end

  def diatonic_intervals
    @diatonic_intervals ||= pitches.each_cons(2).map do |pitch_pair|
      HeadMusic::Analysis::DiatonicInterval.new(*pitch_pair)
    end
  end

  def diatonic_intervals_above_bass_pitch
    @diatonic_intervals_above_bass_pitch ||= pitches_above_bass_pitch.map do |pitch|
      HeadMusic::Analysis::DiatonicInterval.new(bass_pitch, pitch)
    end
  end

  def pitches_above_bass_pitch
    @pitches_above_bass_pitch ||= pitches.drop(1)
  end

  def integer_notation
    # questions:
    # - should this be absolute? 0 = C?
    # - should there be both absolute and relative versions?
    @integer_notation ||= integer_notation_values
  end

  def invert
    inverted_pitch = pitches.first + octave
    new_pitches = pitches.drop(1) + [inverted_pitch]
    HeadMusic::Analysis::PitchCollection.new(new_pitches)
  end

  def uninvert
    inverted_pitch = pitches.last - octave
    new_pitches = [inverted_pitch] + pitches[0..-2]
    HeadMusic::Analysis::PitchCollection.new(new_pitches)
  end

  def bass_pitch
    @bass_pitch ||= pitches.first
  end

  def inspect
    pitches.join(" ")
  end

  def to_s
    pitches.join(" ")
  end

  def ==(other)
    pitches.sort == other.pitches.sort
  end

  def equivalent?(other)
    pitch_classes.sort == other.pitch_classes.sort
  end

  def size
    pitches.length
  end

  def scale_degrees
    @scale_degrees ||= pitches.empty? ? [] : scale_degrees_above_bass_pitch.unshift(1)
  end

  def scale_degrees_above_bass_pitch
    @scale_degrees_above_bass_pitch ||= diatonic_intervals_above_bass_pitch.map(&:simple_number).sort - [8]
  end

  def sonority
    @sonority ||= HeadMusic::Analysis::Sonority.new(self)
  end

  def chord_analysis
    @chord_analysis ||= HeadMusic::Analysis::ChordAnalysis.new(self)
  end

  private

  def octave
    @octave ||= HeadMusic::Analysis::DiatonicInterval.get("perfect octave")
  end

  def integer_notation_values
    return [] if pitches.empty?

    diatonic_intervals_above_bass_pitch.map { |interval| interval.semitones % 12 }.sort.unshift(0).uniq
  end

  def reduction_pitches
    pitches.map { |pitch| folded_into_reduction(pitch) }.sort
  end

  def folded_into_reduction(pitch)
    ceiling = bass_pitch + 12
    pitch = HeadMusic::Rudiment::Pitch.fetch_or_create(pitch.spelling, pitch.register - 1) while pitch > ceiling
    pitch
  end
end
