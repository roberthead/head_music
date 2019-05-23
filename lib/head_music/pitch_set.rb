# frozen_string_literal: true

# A PitchSet is a collection of one or more pitches
class HeadMusic::PitchSet
  attr_reader :pitches

  delegate :intervals, to: :reduction, prefix: true

  def initialize(pitches)
    @pitches = pitches.map { |pitch| HeadMusic::Pitch.get(pitch) }.sort.uniq
  end

  def pitch_classes
    @pitch_classes ||= reduction_pitches.map(&:pitch_class).uniq
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

  private

  def analysis
    @analysis ||= HeadMusic::PitchSet::Analysis.new(self)
  end

  def reduction_pitches
    pitches.map do |pitch|
      pitch = HeadMusic::Pitch.fetch_or_create(pitch.spelling, pitch.octave - 1) while pitch > bass_pitch + 12
      pitch
    end.sort
  end
end
