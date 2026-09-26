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

  def articulate(*)
    raise ArgumentError, "a rest cannot be articulated; the articulation at #{position} needs a note"
  end

  def embellish(*)
    raise ArgumentError, "a rest cannot be ornamented; the ornament at #{position} needs a note"
  end

  def note_dynamic=(_identifier)
    raise ArgumentError, "a rest cannot be accented; the dynamic at #{position} needs a note"
  end
end
