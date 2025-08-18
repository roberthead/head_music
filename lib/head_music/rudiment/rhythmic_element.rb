# A module for music rudiments
module HeadMusic::Rudiment; end

# Abstract base class for rhythmic elements that have a rhythmic value.
# This includes notes (pitched), rests (silence), and unpitched notes (percussion).
class HeadMusic::Rudiment::RhythmicElement < HeadMusic::Rudiment::Base
  include Comparable

  LetterName = HeadMusic::Rudiment::LetterName
  Alteration = HeadMusic::Rudiment::Alteration
  Register = HeadMusic::Rudiment::Register
  RhythmicValue = HeadMusic::Rudiment::RhythmicValue

  attr_reader :rhythmic_value

  delegate :unit, :dots, :tied_value, :ticks, to: :rhythmic_value

  # Make new private to prevent direct instantiation of abstract class
  private_class_method :new

  def initialize(rhythmic_value)
    @rhythmic_value = rhythmic_value
  end

  # Create a new instance with a different rhythmic value
  def with_rhythmic_value(new_rhythmic_value)
    # Use the factory method if available, otherwise use new
    if self.class.respond_to?(:get)
      self.class.get(new_rhythmic_value)
    else
      self.class.send(:new, new_rhythmic_value)
    end
  end

  def ==(other)
    return false unless other.is_a?(self.class)
    rhythmic_value == other.rhythmic_value
  end

  def <=>(other)
    return nil unless other.is_a?(HeadMusic::Rudiment::RhythmicElement)
    rhythmic_value <=> other.rhythmic_value
  end

  def to_s
    name
  end

  # Abstract method - must be implemented by subclasses
  def name
    raise HeadMusic::AbstractMethodError, "Subclasses must implement the name method"
  end

  # Abstract method - must be implemented by subclasses
  def sounded?
    raise HeadMusic::AbstractMethodError, "Subclasses must implement the sounded? method"
  end
end
