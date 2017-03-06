class HeadMusic::Meter
  attr_reader :top_number, :bottom_number

  NAMED = {
    common_time: '4/4',
    cut_time: '2/2'
  }

  def self.get(identifier)
    identifer = identifer.to_s
    hash_key = HeadMusic::Utilities::HashKey.for(identifier)
    time_signature_string = NAMED[hash_key] || identifier
    @meters ||= {}
    @meters[hash_key] ||= new(*time_signature_string.split('/').map(&:to_i))
  end

  def self.default
    get('4/4')
  end

  def self.common_time
    get(:common_time)
  end

  def self.cut_time
    get(:cut_time)
  end

  def initialize(top_number, bottom_number)
    @top_number, @bottom_number = top_number, bottom_number
  end

  def simple?
    !compound?
  end

  def compound?
    top_number > 3 && top_number / 3 == top_number / 3.0
  end

  def duple?
    top_number == 2
  end

  def triple?
    top_number % 3 == 0
  end

  def quadruple?
    top_number == 4
  end

  def beats_per_bar
    compound? ? top_number / 3 : top_number
  end

  def counts_per_bar
    top_number
  end

  def beat_strength(count, tick: 0)
    return 100 if count == 1 && tick == 0
    return 80 if strong_counts.include?(count) && tick == 0
    return 60 if tick == 0
    return 40 if strong_ticks.include?(tick)
    20
  end

  def ticks_per_count
    @ticks_per_count ||= count_unit.ticks
  end

  def strong_ticks
    @strong_ticks ||=
      [2,3,4].map do |sixths|
        ticks_per_count * (sixths / 6.0)
      end
  end

  def count_unit
    HeadMusic::RhythmicUnit.for_denominator_value(bottom_number)
  end

  def beat_unit
    @beat_unit ||=
      if compound?
        unit = HeadMusic::RhythmicUnit.for_denominator_value(bottom_number / 2)
        HeadMusic::RhythmicValue.new(unit, dots: 1)
      else
        HeadMusic::RhythmicValue.new(count_unit)
      end
  end

  def to_s
    [top_number, bottom_number].join('/')
  end

  def ==(other)
    to_s == other.to_s
  end

  def strong_counts
    @strong_counts ||= begin
      (1..counts_per_bar).select do |count|
        count == 1 ||
        count == counts_per_bar / 2.0 + 1 ||
        (
          counts_per_bar % 3 == 0 &&
          counts_per_bar > 6 &&
          count % 3 == 1
        )
      end
    end
  end
end
