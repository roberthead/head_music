# frozen_string_literal: true

# A grand staff is a group of staves for a single instrument, such as a piano.
class HeadMusic::GrandStaff
  GRAND_STAVES = {
    piano: {
      instrument: :piano,
      staves: [
        { clef: :treble, instrument: :piano },
        { clef: :bass, instrument: :piano },
      ],
    },
    organ: {
      instrument: :organ,
      staves: [
        { clef: :treble, instrument: :organ },
        { clef: :bass, instrument: :organ },
        { clef: :bass, instrument: :pedals },
      ],
    },
  }.freeze

  def self.get(name)
    @grand_staves ||= {}
    hash_key = HeadMusic::Utilities::HashKey.for(name)
    return nil unless GRAND_STAVES.key?(hash_key)
    @grand_staves[hash_key] ||= new(hash_key)
  end

  attr_reader :identifier, :data

  def initialize(name)
    @identifier = HeadMusic::Utilities::HashKey.for(name)
    @data = GRAND_STAVES[identifier]
  end

  def instrument
    @instrument ||= HeadMusic::Instrument.get(data[:instrument])
  end

  def staves
    @staves ||=
      data[:staves].map { |staff| HeadMusic::Staff.new(staff[:clef], instrument: staff[:instrument] || instrument) }
  end

  def brace_staves_index_first
    0
  end

  def brace_staves_index_last
    1
  end
end
