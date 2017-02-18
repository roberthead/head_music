class HeadMusic::Octave
  include Comparable

  def self.get(identifier)
    return nil unless identifier.to_s == identifier.to_i.to_s
    return nil unless (-2..12).include?(identifier.to_i)
    @octaves ||= {}
    @octaves[identifier.to_i] ||= new(identifier.to_i)
  end

  attr_reader :number
  delegate :to_i, :to_s, to: :number

  def initialize(number)
    @number ||= number
  end

  def <=>(other)
    self.to_i <=> other.to_i
  end

  private_class_method :new
end
