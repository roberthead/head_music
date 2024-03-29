# frozen_string_literal: true

# A chromatic interval is the distance between two pitches measured in half-steps.
class HeadMusic::ChromaticInterval
  include Comparable

  private_class_method :new

  # TODO: include the Named module
  NAMES = %w[
    perfect_unison minor_second major_second minor_third major_third perfect_fourth tritone perfect_fifth
    minor_sixth major_sixth minor_seventh major_seventh perfect_octave
  ].freeze

  attr_reader :semitones

  def self.get(identifier)
    @intervals ||= {}
    candidate = identifier.to_s.downcase.gsub(/\W+/, "_")
    semitones = NAMES.index(candidate) || identifier.to_i
    @intervals[semitones] ||= new(semitones.to_i)
  end

  def initialize(semitones)
    @semitones = semitones
  end

  def simple
    HeadMusic::ChromaticInterval.get(semitones % 12)
  end

  def simple?
    (0..12).cover?(semitones)
  end

  def compound?
    semitones > 12
  end

  def to_i
    semitones
  end

  def diatonic_name
    NAMES[simple.semitones].tr("_", " ")
  end

  # diatonic set theory
  alias_method :specific_interval, :semitones

  def +(other)
    HeadMusic::ChromaticInterval.get(to_i + other.to_i)
  end

  def -(other)
    HeadMusic::ChromaticInterval.get((to_i - other.to_i).abs)
  end

  def <=>(other)
    to_i <=> other.to_i
  end
end
