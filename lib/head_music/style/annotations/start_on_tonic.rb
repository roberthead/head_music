module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::StartOnTonic < HeadMusic::Style::Annotation
  def message
    'Start on the tonic.'
  end

  def marks
    if first_note && !starts_on_tonic?
      HeadMusic::Style::Mark.for(first_note)
    end
  end

  def starts_on_tonic?
    composition.key_signature.tonic_spelling == first_note.spelling
  end

  def first_note
    notes.first
  end
end
