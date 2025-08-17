# A module for music rudiments
module HeadMusic::Rudiment; end

# A Rest represents a period of silence with a specific rhythmic value.
# It inherits from MusicalElement and has a duration but no pitch.
class HeadMusic::Rudiment::Rest < HeadMusic::Rudiment::MusicalElement
  include HeadMusic::Named

  # Make new public for this concrete class
  public_class_method :new

  def self.get(rhythmic_value)
    return rhythmic_value if rhythmic_value.is_a?(HeadMusic::Rudiment::Rest)

    rhythmic_value = HeadMusic::Content::RhythmicValue.get(rhythmic_value)
    return nil unless rhythmic_value

    fetch_or_create(rhythmic_value)
  end

  def self.fetch_or_create(rhythmic_value)
    @rests ||= {}
    hash_key = rhythmic_value.to_s
    @rests[hash_key] ||= new(rhythmic_value)
  end

  def name
    "#{rhythmic_value} rest"
  end

  # Override with_rhythmic_value to use the Rest factory method
  def with_rhythmic_value(new_rhythmic_value)
    self.class.get(new_rhythmic_value)
  end

  def sounded?
    false
  end

  private_class_method :fetch_or_create
end
