# A module for music rudiments
module HeadMusic::Rudiment; end

# Consonance describes a category or degree of harmonic pleasantness: perfect, imperfect, or dissonant
class HeadMusic::Rudiment::Consonance
  LEVELS = %w[perfect imperfect dissonant].freeze

  def self.get(name)
    @consonances ||= {}
    @consonances[name.to_sym] ||= new(name) if LEVELS.include?(name.to_s)
  end

  attr_reader :name

  delegate :to_s, :to_sym, to: :name

  def initialize(name)
    @name = name.to_s.to_sym
  end

  def ==(other)
    to_s == other.to_s
  end

  LEVELS.each do |method_name|
    define_method(:"#{method_name}?") { to_s == method_name }
  end
end
