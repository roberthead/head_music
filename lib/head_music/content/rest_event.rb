# A module for musical content
module HeadMusic::Content; end

# A voice event that is silent for its duration.
class HeadMusic::Content::RestEvent < HeadMusic::Content::VoiceEvent
  public_class_method :new

  def rest?
    true
  end

  def sing(_text, **)
    raise ArgumentError, "a rest cannot sing; the syllable at #{position} needs a note"
  end
end
