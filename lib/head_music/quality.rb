class HeadMusic::Quality
  SHORTHAND = {
    perfect: 'P',
    major: 'M',
    minor: 'm',
    diminished: 'd',
    augmented: 'A',
    doubly_diminished: 'dd',
    doubly_augmented: 'AA',
  }
  NAMES = SHORTHAND.keys

  PERFECT_INTERVAL_MODIFICATION = {
    -2 => :doubly_diminished,
    -1 => :diminished,
    0 => :perfect,
    1 => :augmented,
    2 => :doubly_augmented
  }

  MAJOR_INTERVAL_MODIFICATION = {
    -2 => :diminished,
    -1 => :minor,
    0 => :major,
    1 => :augmented,
    2 => :doubly_augmented
  }

  def self.get(identifier)
    @qualities ||= {}
    identifier = identifier.to_s.to_sym
    @qualities[identifier] ||= new(identifier) if NAMES.include?(identifier)
  end

  attr_reader :name
  delegate :to_s, to: :name

  def initialize(name)
    @name = name
  end

  def ==(other)
    self.to_s == other.to_s
  end

  def shorthand
    SHORTHAND[name]
  end

  private_class_method :new
end
