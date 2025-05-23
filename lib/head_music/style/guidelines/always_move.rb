# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::AlwaysMove < HeadMusic::Style::Annotation
  MESSAGE = "Always move to a different note."

  def marks
    melodic_note_pairs
      .select { |pair| pair.perfect? && pair.unison? }
      .map { |pair| HeadMusic::Style::Mark.for_all(pair.notes) }
  end
end
