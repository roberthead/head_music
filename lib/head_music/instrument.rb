class HeadMusic::Instrument
  INSTRUMENTS = {
    violin: {
      name: "violin",
      family: :string,
      default_clef: :treble
    },
    piano: {
      name: "piano",
      family: :string,
      default_system: [:treble, :bass]
    }
  }

  def self.get(name)
    @instruments ||= {}
    key = HeadMusic::Utilities::HashKey.for(name)
    @instruments[key] ||= new(name.to_s)
  end

  attr_reader :name
  delegate :to_s, to: :name

  def initialize(name)
    @name = name.to_s
  end

  def data
    @data ||= INSTRUMENTS[hash_key]
  end

  def hash_key
    HeadMusic::Utilities::HashKey.for(name)
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
