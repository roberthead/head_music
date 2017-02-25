class HeadMusic::Instrument
  def self.get(name)
    @instruments ||= {}
    key = name.to_s.downcase.gsub(/\W+/, '_').to_sym
    @instruments[key] ||= new(name.to_s)
  end

  attr_reader :name
  delegate :to_s, to: :name

  def initialize(name)
    @name = name.to_s
  end

  def ==(other)
    to_s == other.to_s
  end
end
