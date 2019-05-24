# frozen_string_literal: true

# A PitchClassSet represents a pitch-class set or pitch collection.
# See also: PitchSet, PitchClass
class HeadMusic::PitchClassSet
  attr_reader :pitch_classes

  delegate :empty?, to: :pitch_classes
  alias empty_set? empty?

  def initialize(identifiers)
    @pitch_classes = identifiers.map { |identifier| HeadMusic::PitchClass.get(identifier) }.uniq.sort
  end

  def inspect
    pitch_classes.map(&:to_s).join(' ')
  end

  def to_s
    pitch_classes.map(&:to_s).join(' ')
  end

  def ==(other)
    pitch_classes == other.pitch_classes
  end

  def equivalent?(other)
    pitch_classes.sort == other.pitch_classes.sort
  end

  def size
    @size ||= pitch_classes.length
  end

  def monad?
    pitch_classes.length == 1
  end

  def dyad?
    pitch_classes.length == 2
  end

  def trichord?
    pitch_classes.length == 3
  end

  def tetrachord?
    pitch_classes.length == 4
  end

  def pentachord?
    pitch_classes.length == 5
  end

  def hexachord?
    pitch_classes.length == 6
  end

  def heptachord?
    pitch_classes.length == 7
  end

  def octachord?
    pitch_classes.length == 8
  end

  def nonachord?
    pitch_classes.length == 9
  end

  def decachord?
    pitch_classes.length == 10
  end

  def undecachord?
    pitch_classes.length == 11
  end

  def dodecachord?
    pitch_classes.length == 12
  end
end
