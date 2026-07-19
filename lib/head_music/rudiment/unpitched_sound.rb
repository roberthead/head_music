module HeadMusic::Rudiment; end

# An unpitched sound: a drum hit, a clap, a percussive knock on any instrument.
# The sound concept is a rudiment, but its vocabulary lives in the instruments
# catalog, so this class references HeadMusic::Instruments::Instrument at
# runtime only (inside methods), leaving require order unaffected.
class HeadMusic::Rudiment::UnpitchedSound < HeadMusic::Rudiment::Base
  GENERIC_NAME = "unpitched"

  attr_reader :instrument

  # Instances are compared by value rather than interned, because inputs are
  # arbitrary strings and an identity cache keyed on them would grow without
  # bound. Only the generic instrument-less sound is memoized as a singleton.
  def self.get(value = nil)
    return generic if value.nil?
    return value if value.is_a?(HeadMusic::Rudiment::UnpitchedSound)

    instrument = HeadMusic::Instruments::Instrument.get(value)
    return nil unless instrument

    new(instrument)
  end

  def self.generic
    @generic ||= new(nil).freeze
  end

  def initialize(instrument)
    @instrument = instrument
  end

  def name
    return GENERIC_NAME unless instrument

    instrument.name
  end

  def name_key
    instrument&.name_key
  end

  def to_s
    name
  end

  # Describes the sound, not the instrument:
  # even a knock on a violin body is unpitched.
  def pitched?
    false
  end

  def ==(other)
    other.is_a?(self.class) && name_key == other.name_key
  end

  alias_method :eql?, :==

  def hash
    [self.class, name_key].hash
  end
end
