# frozen_string_literal: true

class HeadMusic::PitchClass
  attr_reader :number

  SHARP_SPELLINGS = %w[C C# D D# E F F# G G# A A# B].freeze
  FLAT_SPELLINGS = %w[C Db D Eb E F Gb G Ab A Bb B].freeze

  def self.get(identifier)
    @pitch_classes ||= {}
    number = HeadMusic::Spelling.get(identifier).pitch_class.to_i if HeadMusic::Spelling.matching_string(identifier)
    number ||= identifier.to_i % 12
    @pitch_classes[number] ||= new(number)
  end

  class << self
    alias [] get
  end

  def initialize(pitch_class_or_midi_number)
    @number = pitch_class_or_midi_number.to_i % 12
  end

  def to_i
    number
  end

  def +(semitones)
    HeadMusic::PitchClass.get(to_i + semitones.to_i)
  end

  def -(semitones)
    HeadMusic::PitchClass.get(to_i - semitones.to_i)
  end

  def ==(value)
    to_i == value.to_i
  end
  alias enharmonic? ==

  def intervals_to(other)
    delta = other.to_i - to_i
    inverse = delta > 0 ? delta - 12 : delta + 12
    [delta, inverse].sort_by(&:abs).map { |interval| HeadMusic::Interval.get(interval) }
  end

  def smallest_interval_to(other)
    intervals_to(other).first
  end

  private_class_method :new
end
