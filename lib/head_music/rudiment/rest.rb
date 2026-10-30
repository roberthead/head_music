# A module for music rudiments
module HeadMusic::Rudiment; end

# A Rest represents a period of silence with a specific rhythmic duration.
# It inherits from RhythmicElement and has a duration but no pitch.
class HeadMusic::Rudiment::Rest < HeadMusic::Rudiment::RhythmicElement
  include HeadMusic::Named

  # Make new public for this concrete class
  public_class_method :new

  def self.get(rhythmic_duration)
    return rhythmic_duration if rhythmic_duration.is_a?(HeadMusic::Rudiment::Rest)

    rhythmic_duration = HeadMusic::Rudiment::RhythmicDuration.get(rhythmic_duration)
    return nil unless rhythmic_duration

    fetch_or_create(rhythmic_duration)
  end

  def self.fetch_or_create(rhythmic_duration)
    fetch_or_register(rhythmic_duration.to_s, rhythmic_duration)
  end

  def name
    "#{rhythmic_duration} rest"
  end

  def sounded?
    false
  end

  private_class_method :fetch_or_create
end
