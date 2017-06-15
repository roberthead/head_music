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
    overlappings_for_voices(lower_voices, :>)
  end

  def overlappings_of_higher_voices
    overlappings_for_voices(higher_voices, :<)
  end

  def overlappings_for_voices(voices, comparison_operator)
    [].tap do |marks|
      voices.each do |higher_voice|
        overlapped_notes = voice.notes.select do |note|
          preceding_note = higher_voice.note_preceding(note.position)
          following_note = higher_voice.note_following(note.position)
          (preceding_note && preceding_note.pitch.send(comparison_operator, note.pitch)) ||
            (following_note && following_note.pitch.send(comparison_operator, note.pitch))
        end
        marks << HeadMusic::Style::Mark.for_each(overlapped_notes)
      end
    end.flatten.compact
  end
end
