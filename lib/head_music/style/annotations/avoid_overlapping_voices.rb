module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::AvoidOverlappingVoices < HeadMusic::Style::Annotation
  MESSAGE = "Avoid overlapping voices."

  def marks
    overlappings
  end

  private

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
