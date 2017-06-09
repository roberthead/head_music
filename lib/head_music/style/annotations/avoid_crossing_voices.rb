module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::AvoidCrossingVoices < HeadMusic::Style::Annotation
  MESSAGE = "Avoid crossing voices."

  def marks
    crossings
  end

  private

  def crossings
    crossings_of_lower_voices + crossings_of_higher_voices
  end

  def crossings_of_lower_voices
    [].tap do |marks|
      lower_voices.each do |lower_voice|
        lower_voice.notes.each do |lower_voice_note|
          notes_during = voice.notes_during(lower_voice_note)
          crossed_notes = notes_during.select { |note| note.pitch < lower_voice_note.pitch }
          marks << HeadMusic::Style::Mark.for_all(crossed_notes)
        end
      end
    end
  end

  def crossings_of_higher_voices
    [].tap do |marks|
      higher_voices.each do |higher_voice|
        higher_voice.notes.each do |higher_voice_note|
          notes_during = voice.notes_during(higher_voice_note)
          crossed_notes = notes_during.select { |note| note.pitch > lower_voice_note.pitch }
          marks << HeadMusic::Style::Mark.for_all(crossed_notes)
        end
      end
    end
  end
end
