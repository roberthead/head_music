# A module for music rudiments
module HeadMusic::Rudiment; end

# Consonance describes a category or degree of harmonic pleasantness
class HeadMusic::Rudiment::Consonance
  # Detailed categories aligned with music theory
  LEVELS = %w[
    perfect_consonance
    imperfect_consonance
    contextual
    mild_dissonance
    harsh_dissonance
    dissonance
  ].freeze

  # Constants for each consonance level
  PERFECT_CONSONANCE = :perfect_consonance
  IMPERFECT_CONSONANCE = :imperfect_consonance
  CONTEXTUAL = :contextual
  MILD_DISSONANCE = :mild_dissonance
  HARSH_DISSONANCE = :harsh_dissonance
  DISSONANCE = :dissonance

  def self.get(name)
    @consonances ||= {}
    name_sym = name.to_sym
    @consonances[name_sym] ||= new(name) if LEVELS.include?(name.to_s)
  end

  attr_reader :name

  delegate :to_s, :to_sym, to: :name

  def initialize(name)
    @name = name.to_s.to_sym
  end

  def ==(other)
    to_s == other.to_s
  end

  # Check if this represents a consonance (perfect or imperfect)
  def consonant?
    [PERFECT_CONSONANCE, IMPERFECT_CONSONANCE].include?(name)
  end

  # Check if this represents any form of dissonance
  def dissonant?
    [MILD_DISSONANCE, HARSH_DISSONANCE, DISSONANCE].include?(name)
  end

  # Contextual is special - neither strictly consonant nor dissonant
  def contextual?
    name == CONTEXTUAL
  end

  # Predicate methods for each level
  LEVELS.each do |method_name|
    define_method(:"#{method_name}?") { to_s == method_name }
  end
end
