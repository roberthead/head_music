# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# marks the voice if the first note is not the first or fifth scale degree of the key.
class HeadMusic::Style::Guidelines::StartOnPerfectConsonance < HeadMusic::Style::Annotation
  MESSAGE = "Start on the tonic or a perfect consonance above the tonic (unless bass voice)."

  def marks
    return unless first_note

    needs_marking = if bass_voice?
      !starts_on_tonic?
    else
      !starts_on_perfect_consonance?
    end

    HeadMusic::Style::Mark.for(first_note) if needs_marking
  end

  private

  def starts_on_perfect_consonance?
    diatonic_interval_from_tonic(first_note).perfect_consonance?(:two_part_harmony)
  end
end
