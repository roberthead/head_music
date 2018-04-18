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
    reduction.root_triad? || reduction.first_inversion_triad? || reduction.second_inversion_triad?
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

  def reduction
    @reduction ||= HeadMusic::Chord.new(reduction_pitches)
  end

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
    pitches & other.pitches == pitches
  end

  private

  def reduction_pitches
    pitches.map do |pitch|
      pitch = HeadMusic::Pitch.fetch_or_create(pitch.spelling, pitch.octave - 1) while pitch > bass_pitch + 12
      pitch
    end.sort
  end
end
