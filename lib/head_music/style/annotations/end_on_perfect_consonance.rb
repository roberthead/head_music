module HeadMusic::Style::Annotations
end

# marks the voice if the first note is not the first or fifth scale degree of the key.
class HeadMusic::Style::Annotations::EndOnPerfectConsonance < HeadMusic::Style::Annotation
  MESSAGE = 'End on the first or the fifth scale degree.'

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
