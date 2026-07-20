# A module for music rudiments
module HeadMusic::Rudiment; end

# Base class for enharmonic equivalence relationships between rudiments.
# An enharmonic equivalent is the same sound spelled differently, such as D# and Eb.
# Subclasses declare their subject class and implement #enharmonic_equivalent?.
class HeadMusic::Rudiment::EnharmonicEquivalence
  def self.get(subject)
    subject = subject_class.get(subject)
    @enharmonic_equivalences ||= {}
    @enharmonic_equivalences[subject.to_s] ||= new(subject)
  end

  def self.subject_class
    raise NotImplementedError, "Subclasses must implement .subject_class"
  end

  attr_reader :subject

  def initialize(subject)
    @subject = self.class.subject_class.get(subject)
  end

  def enharmonic?(other)
    enharmonic_equivalent?(other)
  end

  def equivalent?(other)
    enharmonic_equivalent?(other)
  end

  private_class_method :new
end
