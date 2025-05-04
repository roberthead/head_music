# Accepts the letter name count between two notes and categorizes the interval
class HeadMusic::Analysis::DiatonicInterval::Category
  attr_reader :number

  def initialize(number)
    @number = number
  end

  def step?
    number == 2
  end

  def skip?
    number == 3
  end

  def leap?
    number >= 3
  end

  def large_leap?
    number > 3
  end
end
