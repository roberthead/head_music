class HeadMusic::Meter
  attr_reader :top_number, :bottom_number

  NAMED = {
    common_time: '4/4',
    cut_time: '2/2'
  }

  def self.get(identifier)
    identifer = identifer.to_s
    identifier = NAMED[identifier.to_sym] || identifier
    new(*identifier.split('/').map(&:to_i))
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

  def to_s
    [top_number, bottom_number].join('/')
  end

  def ==(other)
    to_s == other.to_s
  end
end
