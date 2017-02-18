class HeadMusic::Quality
  QUALITY_NAMES = %w[perfect major minor diminished augmented].map(&:to_sym)

  def self.get(identifier)
    @qualities ||= {}
    identifier = identifier.to_sym
    @qualities[identifier] = new(identifier) if QUALITY_NAMES.include?(identifier)
  end

  attr_reader :name
  delegate :to_s, to: :name

  def initialize(name)
    @name = name
  end

  def ==(other)
    self.to_s == other.to_s
  end

  private_class_method :new
end
