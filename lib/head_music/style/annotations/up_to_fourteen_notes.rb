# frozen_string_literal: true

module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::UpToFourteenNotes < HeadMusic::Style::Annotation
  MAXIMUM_NOTES = 14

  MESSAGE = 'Write up to fourteen notes.'

  def marks
    HeadMusic::Style::Mark.for_each(notes[MAXIMUM_NOTES..-1]) if overage > 0
  end

  private

  def overage
    [notes.length - MAXIMUM_NOTES, 0].max
  end
end
