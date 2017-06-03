module HeadMusic::Style::Annotations
end

# marks the voice if the first note is not the first or fifth scale degree of the key.
class HeadMusic::Style::Annotations::StartOnPerfectConsonance < HeadMusic::Style::Annotation
  def message
    'Start on the tonic or a perfect consonance above the tonic.'
  end

  def marks
    if first_note && !starts_on_perfect_consonance?
      HeadMusic::Style::Mark.for(first_note)
    end
  end

  private

  def starts_on_perfect_consonance?
    functional_interval.perfect_consonance?(:two_part_harmony)
  end

  def functional_interval
    HeadMusic::FunctionalInterval.new(composition.key_signature.tonic_spelling, first_note.spelling)
  end

  def first_note
    notes.first
  end
end
