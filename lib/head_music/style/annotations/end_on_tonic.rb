# frozen_string_literal: true

# Module for Annotations.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::EndOnTonic < HeadMusic::Style::Annotation
  MESSAGE = 'End on the first scale degree.'

  def marks
    HeadMusic::Style::Mark.for(notes.last) if notes.any? && !ends_on_tonic?
  end

  private

  def ends_on_tonic?
    tonic_spelling == last_note_spelling
  end

  def last_note_spelling
    last_note&.spelling
  end
end
