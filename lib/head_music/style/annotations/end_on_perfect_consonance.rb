module HeadMusic::Style::Annotations
end

# marks the voice if the first note is not the first or fifth scale degree of the key.
class HeadMusic::Style::Annotations::EndOnPerfectConsonance < HeadMusic::Style::Annotation
  def message
    'End on the tonic or a perfect consonance above the tonic.'
  end

  def marks
    if last_note && !ends_on_perfect_consonance?
      HeadMusic::Style::Mark.for(last_note)
    end
  end

  private

  def ends_on_perfect_consonance?
    functional_interval_from_tonic(last_note).perfect_consonance?(:two_part_harmony)
  end
end
