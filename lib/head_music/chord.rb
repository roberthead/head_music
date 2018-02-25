# frozen_string_literal: true

# A Chord is a collection of three or more pitches
class HeadMusic::Chord
  attr_reader :pitches

  def initialize(pitches)
    raise ArgumentError if pitches.length < 3
    @pitches = pitches.map { |pitch| HeadMusic::Pitch.get(pitch) }.sort
  end

  def consonant_triad?
    return false unless three_pitches?
    root_triad? || first_inversion_triad? || second_inversion_triad?
  end

  def root_triad?
    intervals.map(&:shorthand).sort == %w[M3 m3]
  end

  def first_inversion_triad?
    invert.invert.intervals.map(&:shorthand).sort == %w[M3 m3]
  end

  def second_inversion_triad?
    invert.intervals.map(&:shorthand).sort == %w[M3 m3]
  end

  # TODO
  def reduction; end

  def three_pitches?
    pitches.length == 3
  end

  def intervals
    pitches.each_cons(2).map do |pitch_pair|
      HeadMusic::FunctionalInterval.new(*pitch_pair)
    end
  end

  def invert
    inverted_pitch = pitches[0] + HeadMusic::Interval.get(12)
    new_pitches = pitches.drop(1) + [inverted_pitch]
    HeadMusic::Chord.new(new_pitches)
  end
end
