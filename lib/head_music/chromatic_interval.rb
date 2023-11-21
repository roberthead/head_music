# frozen_string_literal: true

# A chromatic interval is the distance between two pitches measured in half-steps.
class HeadMusic::ChromaticInterval
  include Comparable
  include HeadMusic::Named

  private_class_method :new

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

  def initialize(identifier)
    if identifier.to_s.strip =~ /^\D/i
      candidate = identifier.to_s.downcase.gsub(/\W+/, "_")
      semitones = NAMES.index(candidate) || identifier.to_i
    end
    @semitones = semitones || identifier.to_i
    set_name
  end

  def set_name
    candidate = semitones
    while name.nil? && candidate > 0
      self.name = NAMES[candidate]
      candidate -= 12
    end
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
