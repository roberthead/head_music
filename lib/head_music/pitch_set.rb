# frozen_string_literal: true

# A PitchSet is a collection of one or more pitches.
# See also: PitchClassSet
class HeadMusic::PitchSet
  attr_reader :pitches

  delegate :intervals, to: :reduction, prefix: true
  delegate :empty?, :empty_set?, to: :pitch_class_set
  delegate :monad?, :dyad?, :trichord?, :tetrachord?, :pentachord?, :hexachord?, to: :pitch_class_set
  delegate :heptachord?, :octachord?, :nonachord?, :decachord?, :undecachord?, :dodecachord?, to: :pitch_class_set
  delegate :size, to: :pitch_class_set, prefix: :pitch_class

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

  def intervals
    @intervals ||= pitches.each_cons(2).map do |pitch_pair|
      HeadMusic::FunctionalInterval.new(*pitch_pair)
    end
  end

  def invert
    inverted_pitch = pitches[0] + HeadMusic::Interval.get(12)
    new_pitches = pitches.drop(1) + [inverted_pitch]
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

  def pitch_class_size
    pitch_classes.length
  end

  def triad?
    root_triad? || first_inversion_triad? || second_inversion_triad?
  end

  def consonant_triad?
    major_triad? || minor_triad?
  end

  def major_triad?
    [%w[M3 m3], %w[m3 P4], %w[P4 M3]].include? reduction_intervals.map(&:shorthand)
  end

  def minor_triad?
    [%w[m3 M3], %w[M3 P4], %w[P4 m3]].include? reduction_intervals.map(&:shorthand)
  end

  def root_triad?
    trichord? && reduction_intervals.all?(&:third?)
  end

  def first_inversion_triad?
    trichord? && reduction.invert.invert.intervals.all?(&:third?)
  end

  def second_inversion_triad?
    trichord? && reduction.invert.intervals.all?(&:third?)
  end

  private

  def reduction_pitches
    pitches.map do |pitch|
      pitch = HeadMusic::Pitch.fetch_or_create(pitch.spelling, pitch.octave - 1) while pitch > bass_pitch + 12
      pitch
    end.sort
  end
end
