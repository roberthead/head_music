# A module for music rudiments
module HeadMusic::Rudiment; end

# An UnpitchedNote represents a percussion note with rhythm but no specific pitch.
# It inherits from RhythmicElement and can optionally have an instrument name.
class HeadMusic::Rudiment::UnpitchedNote < HeadMusic::Rudiment::RhythmicElement
  include HeadMusic::Named

  attr_reader :instrument_name

  # Make new public for this concrete class
  public_class_method :new

  def self.get(rhythmic_value, instrument: nil)
    return rhythmic_value if rhythmic_value.is_a?(HeadMusic::Rudiment::UnpitchedNote)

    rhythmic_value = HeadMusic::Content::RhythmicValue.get(rhythmic_value)
    return nil unless rhythmic_value

    fetch_or_create(rhythmic_value, instrument)
  end

  def self.fetch_or_create(rhythmic_value, instrument_name)
    @unpitched_notes ||= {}
    hash_key = [rhythmic_value.to_s, instrument_name].compact.join("_")
    @unpitched_notes[hash_key] ||= new(rhythmic_value, instrument_name)
  end

  def initialize(rhythmic_value, instrument_name = nil)
    super(rhythmic_value)
    @instrument_name = instrument_name
  end

  def name
    if instrument_name
      "#{rhythmic_value} #{instrument_name}"
    else
      "#{rhythmic_value} unpitched note"
    end
  end

  # Override with_rhythmic_value to preserve instrument
  def with_rhythmic_value(new_rhythmic_value)
    self.class.get(new_rhythmic_value, instrument: instrument_name)
  end

  # Create a new unpitched note with a different instrument
  def with_instrument(new_instrument_name)
    self.class.get(rhythmic_value, instrument: new_instrument_name)
  end

  def ==(other)
    return false unless other.is_a?(self.class)
    rhythmic_value == other.rhythmic_value && instrument_name == other.instrument_name
  end

  def sounded?
    true
  end

  private_class_method :fetch_or_create
end
