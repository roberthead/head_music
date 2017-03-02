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

  def beats_per_measure
    compound? ? top_number / 3 : top_number
  end

  def counts_per_measure
    top_number
  end

  def beat_strength(count, ticks: 0)
    return 100 if count == 1 && ticks == 0
    return 80 if strong_counts.include?(count) && ticks == 0
    return 60 if ticks == 0
    divisions = (1..5).map { |sixths| RhythmicValue::PPQN * sixths / 6 }
    return 40 if divisions.include?(ticks)
    20
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
      (1..counts_per_measure).select do |count|
        count == 1 ||
        count == counts_per_measure / 2.0 + 1 ||
        (
          counts_per_measure % 3 == 0 &&
          counts_per_measure > 6 &&
          count % 3 == 1
        )
      end
    end
  end
end
