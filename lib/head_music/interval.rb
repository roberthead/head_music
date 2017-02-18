class HeadMusic::Interval
  include Comparable

  private_class_method :new

  NAMES = %w{perfect_unison minor_second major_second minor_third major_third perfect_fourth tritone perfect_fifth minor_sixth major_sixth minor_seventh major_seventh perfect_octave}

  attr_reader :semitones

  def self.get(semitones)
    @intervals_memo ||= {}
    @intervals_memo[semitones.to_i] ||= new(semitones.to_i)
  end

  def self.named(name)
    name = name.to_s
    get(NAMES.index(name)) if NAMES.include?(name)
  end

  def initialize(semitones)
    @semitones = semitones
  end

  def simplified
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
