# frozen_string_literal: true

# An instrument can be assigned to a staff.
class HeadMusic::Instrument
  include HeadMusic::Named

  INSTRUMENTS = {
    violin: {
      name: 'violin',
      family: :string,
      default_clef: :treble_clef,
    },
    piano: {
      name: 'piano',
      family: :string,
      default_system: %i[treble_clef bass_clef],
    },
  }.freeze

  def self.get(name)
    get_by_name(name)
  end

  def initialize(name)
    self.name = name.to_s
  end

  def data
    @data ||= INSTRUMENTS[hash_key]
  end

  def family
    data[:family]
  end

  def default_system
    data[:default_system]
  end

  def default_clef
    data[:default_clef]
  end

  def ==(other)
    to_s == other.to_s
  end
end
