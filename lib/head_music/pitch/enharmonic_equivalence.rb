# An enharmonic equivalent pitch is the same frequency spelled differently, such as D# and Eb.
class HeadMusic::Pitch::EnharmonicEquivalence
  def self.get(pitch)
    pitch = HeadMusic::Pitch.get(pitch)
    @enharmonic_equivalences ||= {}
    @enharmonic_equivalences[pitch.to_s] ||= new(pitch)
  end

  attr_reader :pitch

  delegate :pitch_class, to: :pitch

  def initialize(pitch)
    @pitch = HeadMusic::Pitch.get(pitch)
  end

  def enharmonic_equivalent?(other)
    other = HeadMusic::Pitch.get(other)
    pitch.midi_note_number == other.midi_note_number && pitch.spelling != other.spelling
  end

  alias_method :enharmonic?, :enharmonic_equivalent?
  alias_method :equivalent?, :enharmonic_equivalent?

  private_class_method :new
end
