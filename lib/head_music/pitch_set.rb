# frozen_string_literal: true

# A PitchSet is a collection of one or more pitches.
# See also: PitchClassSet
class HeadMusic::PitchSet
  TERTIAL_SONORITIES = {
    implied_triad: [3],
    triad: [3, 5],
    seventh_chord: [3, 5, 7],
    ninth_chord: [2, 3, 5, 7],
    eleventh_chord: [2, 3, 4, 5, 7],
    thirteenth_chord: [2, 3, 4, 5, 6, 7],
  }.freeze

  attr_reader :pitches

  delegate :diatonic_intervals, to: :reduction, prefix: true
  delegate :empty?, :empty_set?, to: :pitch_class_set
  delegate :monad?, :dyad?, :trichord?, :tetrachord?, :pentachord?, :hexachord?, to: :pitch_class_set
  delegate :heptachord?, :octachord?, :nonachord?, :decachord?, :undecachord?, :dodecachord?, to: :pitch_class_set
  delegate :size, to: :pitch_class_set, prefix: true

  def initialize(pitches)
    @pitches = pitches.map { |pitch| HeadMusic::Pitch.get(pitch) }.sort.uniq
  end

  def pitch_classes
    @pitch_classes ||= reduction_pitches.map(&:pitch_class).uniq
  end

  def pitch_class_set
    @pitch_class_set ||= HeadMusic::PitchClassSet.new(pitch_classes)
  end

  def reduction
    @reduction ||= HeadMusic::PitchSet.new(reduction_pitches)
  end

  def diatonic_intervals
    @diatonic_intervals ||= pitches.each_cons(2).map do |pitch_pair|
      HeadMusic::DiatonicInterval.new(*pitch_pair)
    end
  end

  def diatonic_intervals_above_bass_pitch
    @diatonic_intervals_above_bass_pitch ||= pitches_above_bass_pitch.map do |pitch|
      HeadMusic::DiatonicInterval.new(bass_pitch, pitch)
    end
  end

  def pitches_above_bass_pitch
    @pitches_above_bass_pitch ||= pitches.drop(1)
  end

  def integer_notation
    @integer_notation ||= begin
      return [] if pitches.empty?
      diatonic_intervals_above_bass_pitch.map { |interval| interval.semitones % 12 }.flatten.sort.unshift(0)
    end
  end

  def invert
    inverted_pitch = pitches[0] + HeadMusic::DiatonicInterval.get('perfect octave')
    new_pitches = pitches.drop(1) + [inverted_pitch]
    HeadMusic::PitchSet.new(new_pitches)
  end

  def uninvert
    inverted_pitch = pitches[-1] - HeadMusic::DiatonicInterval.get('perfect octave')
    new_pitches = [inverted_pitch] + pitches[0..-2]
    HeadMusic::PitchSet.new(new_pitches)
  end

  def bass_pitch
    @bass_pitch ||= pitches.first
  end

  def inspect
    pitches.map(&:to_s).join(' ')
  end

  def to_s
    pitches.map(&:to_s).join(' ')
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

  def triad?
    trichord? && tertial?
  end

  def consonant_triad?
    major_triad? || minor_triad?
  end

  def major_triad?
    [%w[M3 m3], %w[m3 P4], %w[P4 M3]].include? reduction_diatonic_intervals.map(&:shorthand)
  end

  def minor_triad?
    [%w[m3 M3], %w[M3 P4], %w[P4 m3]].include? reduction_diatonic_intervals.map(&:shorthand)
  end

  def diminished_triad?
    [%w[m3 m3], %w[m3 A4], %w[A4 m3]].include? reduction_diatonic_intervals.map(&:shorthand)
  end

  def augmented_triad?
    [%w[M3 M3], %w[M3 d4], %w[d4 M3]].include? reduction_diatonic_intervals.map(&:shorthand)
  end

  def root_position_triad?
    trichord? && reduction_diatonic_intervals.all?(&:third?)
  end

  def first_inversion_triad?
    trichord? && reduction.uninvert.diatonic_intervals.all?(&:third?)
  end

  def second_inversion_triad?
    trichord? && reduction.invert.diatonic_intervals.all?(&:third?)
  end

  def seventh_chord?
    tetrachord? && tertial?
  end

  def root_position_seventh_chord?
    tetrachord? && reduction_diatonic_intervals.all?(&:third?)
  end

  def first_inversion_seventh_chord?
    tetrachord? && reduction.uninvert.diatonic_intervals.all?(&:third?)
  end

  def second_inversion_seventh_chord?
    tetrachord? && reduction.uninvert.uninvert.diatonic_intervals.all?(&:third?)
  end

  def third_inversion_seventh_chord?
    tetrachord? && reduction.invert.diatonic_intervals.all?(&:third?)
  end

  def ninth_chord?
    pentachord? && tertial?
  end

  def eleventh_chord?
    hexachord? && tertial?
  end

  def thirteenth_chord?
    heptachord? && tertial?
  end

  def tertial?
    return false unless diatonic_intervals.any?

    inversion = reduction
    pitches.length.times do
      return true if TERTIAL_SONORITIES.value?(inversion.scale_degrees_above_bass_pitch)
      inversion = inversion.invert
    end
    false
  end

  def scale_degrees
    @scale_degrees ||= pitches.empty? ? [] : scale_degrees_above_bass_pitch.unshift(1)
  end

  def scale_degrees_above_bass_pitch
    @scale_degrees_above_bass_pitch ||= diatonic_intervals_above_bass_pitch.map(&:simple_number).sort - [8]
  end

  private

  def reduction_pitches
    pitches.map do |pitch|
      pitch = HeadMusic::Pitch.fetch_or_create(pitch.spelling, pitch.octave - 1) while pitch > bass_pitch + 12
      pitch
    end.sort
  end
end
