module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::EndOnTonic < HeadMusic::Style::Annotation
  MESSAGE = 'End on the tonic.'

  def marks
    if !notes.empty? && !ends_on_tonic?
      HeadMusic::Style::Mark.for(notes.last)
    end
  end

  private

  def ends_on_tonic?
    tonic_spelling == last_note_spelling
  end

  def last_note_spelling
    last_note && last_note.spelling
  end
end
