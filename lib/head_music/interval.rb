# frozen_string_literal: true

# An interval is the distance between two pitches.
class HeadMusic::Interval
  include Comparable

  private_class_method :new

  NAMES = %w[perfect_unison minor_second major_second minor_third major_third perfect_fourth tritone perfect_fifth minor_sixth major_sixth minor_seventh major_seventh perfect_octave].freeze

  attr_reader :semitones

  def self.get(identifier)
    @intervals ||= {}
    candidate = identifier.to_s.downcase.gsub(/\W+/, '_')
    semitones = NAMES.index(candidate) || identifier.to_i
    @intervals[semitones] ||= new(semitones.to_i)
  end

  def initialize(semitones)
    @semitones = semitones
  end

  def simple
    HeadMusic::Interval.get(semitones % 12)
  end

  def simple?
    (0..12).include?(semitones)
  end

  def compound?
    semitones > 12
  end

  def to_i
    semitones
  end

  def +(value)
    HeadMusic::Interval.get(to_i + value.to_i)
  end

  def -(value)
    HeadMusic::Interval.get((to_i - value.to_i).abs)
  end

  def <=>(other)
    self.to_i <=> other.to_i
  end
end
