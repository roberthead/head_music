module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::OneToOne < HeadMusic::Style::Annotation
  def message
    'Place a note for each note in the other voice.'
  end

  def marks
    if other_voice && other_voice.notes.length > 0
      HeadMusic::Style::Mark.for_each(
        notes_without_match(voice, other_voice) + notes_without_match(other_voice, voice)
      )
    end
  end

  private

  def notes_without_match(voice1, voice2)
    voice1.notes.reject do |voice1_note|
      voice2.notes.map(&:position).include?(voice1_note.position)
    end
  end

  def other_voice
    other_voices.detect(&:cantus_firmus?) || other_voices.first
  end

  def other_voices
    @other_voices ||= voice.composition.voices.select { |part| part != voice }
  end
end
