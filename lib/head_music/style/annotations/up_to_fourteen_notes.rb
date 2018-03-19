# frozen_string_literal: true

# Module for Annotations.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::UpToFourteenNotes < HeadMusic::Style::Annotation
  MAXIMUM_NOTES = 14

  MESSAGE = 'Write up to fourteen notes.'

  def marks
    HeadMusic::Style::Mark.for_each(notes[MAXIMUM_NOTES..-1]) if overage.positive?
  end

  private

  def overage
    [notes.length - MAXIMUM_NOTES, 0].max
  end
end
