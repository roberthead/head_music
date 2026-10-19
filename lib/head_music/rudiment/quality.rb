# A module for music rudiments
module HeadMusic::Rudiment; end

# A quality is a categorization of an interval.
class HeadMusic::Rudiment::Quality < HeadMusic::Rudiment::Base
  SHORTHAND = {
    perfect: "P",
    major: "M",
    minor: "m",
    diminished: "d",
    augmented: "A",
    doubly_diminished: "dd",
    doubly_augmented: "AA"
  }.freeze
  NAMES = SHORTHAND.keys

  PERFECT_INTERVAL_MODIFICATION = {
    -2 => :doubly_diminished,
    -1 => :diminished,
    0 => :perfect,
    1 => :augmented,
    2 => :doubly_augmented
  }.freeze

  MAJOR_INTERVAL_MODIFICATION = {
    -2 => :diminished,
    -1 => :minor,
    0 => :major,
    1 => :augmented,
    2 => :doubly_augmented
  }.freeze

  def self.get(identifier)
    identifier = key(identifier)
    fetch_or_register(identifier) if NAMES.include?(identifier)
  end

  def self.key(identifier)
    identifier.to_s.tr(" ", "_").to_sym
  end
  private_class_method :key

  def self.from(starting_quality, delta)
    case starting_quality
    when :perfect
      PERFECT_INTERVAL_MODIFICATION[delta].to_s.gsub(/_+/, " ")
    when :major
      MAJOR_INTERVAL_MODIFICATION[delta].to_s.gsub(/_+/, " ")
    end
  end

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def to_s
    name.to_s.tr("_", " ")
  end

  def ==(other)
    to_s == other.to_s.tr("_", " ")
  end

  def shorthand
    SHORTHAND[name]
  end

  def article
    %w[a e i o u h].include?(name.to_s.first) ? "an" : "a"
  end

  NAMES.each do |method_name|
    define_method(:"#{method_name}?") { name == method_name }
  end

  private_class_method :new
end
