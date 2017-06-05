module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::DistinctVoices < HeadMusic::Style::Annotation
  def message
    "Avoid crossing or overlapping voices."
  end

  def marks
    crossings + overlappings
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

  def overlappings
    overlappings_of_lower_voices + overlappings_of_higher_voices
  end

  def overlappings_of_lower_voices
    [].tap do |marks|
      lower_voices.each do |lower_voice|
        overlapped_notes = voice.notes.select do |note|
          preceding_note = lower_voice.note_preceding(note.position)
          following_note = lower_voice.note_following(note.position)
          (preceding_note && preceding_note.pitch > note.pitch) || (following_note && following_note.pitch > note.pitch)
        end
        marks << HeadMusic::Style::Mark.for_each(overlapped_notes)
      end
    end
  end

  def overlappings_of_higher_voices
    [].tap do |marks|
      higher_voices.each do |higher_voice|
        overlapped_notes = voice.notes.select do |note|
          preceding_note = higher_voice.note_preceding(note.position)
          following_note = lower_voice.note_following(note.position)
          (preceding_note && preceding_note.pitch < note.pitch) || (following_note && following_note.pitch < note.pitch)
        end
        marks << HeadMusic::Style::Mark.for_each(overlapped_notes)
      end
    end
  end
end
