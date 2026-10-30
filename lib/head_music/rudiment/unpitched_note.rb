# A module for music rudiments
module HeadMusic::Rudiment; end

# An UnpitchedNote represents a percussion note with rhythm but no specific pitch.
# It inherits from RhythmicElement and can optionally have an instrument name.
# Intended future flow: UnpitchedNote ≈ UnpitchedSound + rhythmic duration.
class HeadMusic::Rudiment::UnpitchedNote < HeadMusic::Rudiment::RhythmicElement
  include HeadMusic::Named
  include HeadMusic::ValueEquality

  attr_reader :instrument_name

  value_equality :rhythmic_duration, :instrument_name

  # Make new public for this concrete class
  public_class_method :new

  def self.get(rhythmic_duration, instrument: nil)
    return rhythmic_duration if rhythmic_duration.is_a?(HeadMusic::Rudiment::UnpitchedNote)

    rhythmic_duration = HeadMusic::Rudiment::RhythmicDuration.get(rhythmic_duration)
    return nil unless rhythmic_duration

    fetch_or_create(rhythmic_duration, instrument)
  end

  def self.fetch_or_create(rhythmic_duration, instrument_name)
    hash_key = [rhythmic_duration.to_s, instrument_name].compact.join("_")
    fetch_or_register(hash_key, rhythmic_duration, instrument_name)
  end

  def initialize(rhythmic_duration, instrument_name = nil)
    super(rhythmic_duration)
    @instrument_name = instrument_name
  end

  def name
    if instrument_name
      "#{rhythmic_duration} #{instrument_name}"
    else
      "#{rhythmic_duration} unpitched note"
    end
  end

  # Override with_rhythmic_duration to preserve instrument
  def with_rhythmic_duration(new_rhythmic_duration)
    self.class.get(new_rhythmic_duration, instrument: instrument_name)
  end

  # Create a new unpitched note with a different instrument
  def with_instrument(new_instrument_name)
    self.class.get(rhythmic_duration, instrument: new_instrument_name)
  end

  def sounded?
    true
  end

  private_class_method :fetch_or_create
end
