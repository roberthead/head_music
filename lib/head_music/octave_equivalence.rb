# frozen_string_literal: true

# Octave equivalence is the functional equivalence of pitches with the same spelling separated by one or more octaves.
class HeadMusic::OctaveEquivalence
  def self.get(pitch)
    @octave_equivalences ||= {}
    @octave_equivalences[pitch.to_s] ||= new(pitch)
  end

  def self.definition
    'Octave equivalence is the functional equivalence of pitches with the same spelling separated by one or more octaves.'
  end

  attr_reader :pitch

  def initialize(pitch)
    @pitch = pitch
  end

  def octave_equivalent?(other)
    other = HeadMusic::Pitch.get(other)
    pitch.spelling == other.spelling && pitch.octave != other.octave
  end

  private_class_method :new
end
