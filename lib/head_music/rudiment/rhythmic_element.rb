# A module for music rudiments
module HeadMusic::Rudiment; end

# Abstract base class for rhythmic elements that have a rhythmic duration.
# This includes notes (pitched), rests (silence), and unpitched notes (percussion).
class HeadMusic::Rudiment::RhythmicElement < HeadMusic::Rudiment::Base
  include Comparable

  LetterName = HeadMusic::Rudiment::LetterName
  Alteration = HeadMusic::Rudiment::Alteration
  Register = HeadMusic::Rudiment::Register

  attr_reader :rhythmic_duration

  delegate :ticks, to: :rhythmic_duration

  # Make new private to prevent direct instantiation of abstract class
  private_class_method :new

  def initialize(rhythmic_duration)
    @rhythmic_duration = rhythmic_duration
  end

  # Create a new instance with a different rhythmic duration
  def with_rhythmic_duration(new_rhythmic_duration)
    self.class.get(new_rhythmic_duration)
  end

  def ==(other)
    return false unless other.is_a?(self.class)
    rhythmic_duration == other.rhythmic_duration
  end

  def <=>(other)
    return nil unless other.is_a?(HeadMusic::Rudiment::RhythmicElement)
    rhythmic_duration <=> other.rhythmic_duration
  end

  def to_s
    name
  end

  # Abstract method - must be implemented by subclasses
  def name
    raise NotImplementedError, "Subclasses must implement the name method"
  end

  # Abstract method - must be implemented by subclasses
  def sounded?
    raise NotImplementedError, "Subclasses must implement the sounded? method"
  end
end
