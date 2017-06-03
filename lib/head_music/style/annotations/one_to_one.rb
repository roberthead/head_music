module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::OneToOne < HeadMusic::Style::Annotation
  def message
    'Place a note for each note in the other voice.'
  end

  def marks
    if cantus_firmus && cantus_firmus.notes.length > 0
      HeadMusic::Style::Mark.for_each(
        notes_without_match(voice, cantus_firmus) + notes_without_match(cantus_firmus, voice)
      )
    end
  end

  private

  def notes_without_match(voice1, voice2)
    voice1.notes.reject do |voice1_note|
      voice2.notes.map(&:position).include?(voice1_note.position)
    end
  end
end
