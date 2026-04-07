# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Once the first note has sounded, no rests are permitted for the remainder
# of the voice. Rests before the first note (a leading rest) are allowed.
class HeadMusic::Style::Guidelines::NoRestsAfterNote < HeadMusic::Style::Annotation
  MESSAGE = "Do not rest after the first note has sounded."

  def marks
    return [] if rests.empty? || notes.empty?

    HeadMusic::Style::Mark.for_each(rests_after_first_note)
  end

  private

  def rests_after_first_note
    rests.select { |rest| rest.position >= first_note.position }
  end
end
