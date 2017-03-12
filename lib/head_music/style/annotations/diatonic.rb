module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::Diatonic < HeadMusic::Style::Annotation
  def message
    "Use only notes in the key signature."
  end

  def marks
    HeadMusic::Style::Mark.for_each(notes_not_in_key)
  end
end
