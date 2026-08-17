# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# marks the voice if the first note is not the first or fifth scale degree of the key.
class HeadMusic::Style::Guidelines::EndOnPerfectConsonance < HeadMusic::Style::Guideline
  def marks
    HeadMusic::Style::Mark.for(last_note) if last_note && !ends_on_perfect_consonance?
  end

  private

  def ends_on_perfect_consonance?
    diatonic_interval_from_tonic(last_note).perfect_consonance?(:two_part_harmony)
  end
end
