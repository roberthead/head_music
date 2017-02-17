class HeadMusic::PitchClass
  attr_reader :number

  PREFERRED_SPELLINGS = %w[C C# D Eb E F F# G Ab A Bb B]

  def self.get(number)
    @pitch_classes ||= {}
    number = number.to_i % 12
    @pitch_classes[number] ||= new(number)
  end

  class << self
    alias_method :[], :get
  end

  def initialize(pitch_class_or_midi_number)
    @number = pitch_class_or_midi_number % 12
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
