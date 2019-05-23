# frozen_string_literal: true

# A PitchSet::Analysis provides analysis information about a pitch set.
class HeadMusic::PitchSet::Analysis
  attr_reader :pitch_set

  delegate :pitches, :pitch_classes, :reduction, :reduction_intervals, to: :pitch_set
  delegate :empty?, to: :pitches

  alias empty_set? empty?

  def initialize(pitch_set)
    @pitch_set = pitch_set
  end

  def monad?
    pitch_classes.length == 1
  end

  def dyad?
    pitch_classes.length == 2
  end

  def trichord?
    pitch_classes.length == 3
  end

  def tetrachord?
    pitch_classes.length == 4
  end

  def pentachord?
    pitch_classes.length == 5
  end

  def hexachord?
    pitch_classes.length == 6
  end

  def heptachord?
    pitch_classes.length == 7
  end

  def octachord?
    pitch_classes.length == 8
  end

  def nonachord?
    pitch_classes.length == 9
  end

  def decachord?
    pitch_classes.length == 10
  end

  def undecachord?
    pitch_classes.length == 11
  end

  def dodecachord?
    pitch_classes.length == 12
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
    return false unless trichord?

    reduction_intervals.all?(&:third?)
  end

  def first_inversion_triad?
    return false unless trichord?

    reduction.invert.invert.intervals.all?(&:third?)
  end

  def second_inversion_triad?
    return false unless trichord?

    reduction.invert.intervals.all?(&:third?)
  end
end
