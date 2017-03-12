module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::EndOnTonic < HeadMusic::Style::Annotation
  def message
    'End on the tonic.'
  end

  def marks
    if !notes.empty? && !ends_on_tonic?
      HeadMusic::Style::Mark.for(notes.last)
    end
  end

  private

  def ends_on_tonic?
    notes &&
    notes.last &&
    composition &&
    composition.key_signature &&
    composition.key_signature.tonic_spelling == notes.last.spelling
  end
end
