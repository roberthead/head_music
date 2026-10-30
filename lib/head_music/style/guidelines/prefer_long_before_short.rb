# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Two quarters opening a bar and a longer note closing it make a static point
# that blocks the flow into the next bar, unless the longer note ties over
# (Salzer and Schachter, p. 103). Fux marks the shape N.B. in figure 88.
class HeadMusic::Style::Guidelines::PreferLongBeforeShort < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guideline::BarSpan

  strength :weak, because: "Fux calls the alternative better rather than calling this shape wrong"

  def marks
    return [] if notes.empty?

    (first_bar_number..last_bar_number).filter_map do |bar_number|
      opening = notes_in_bar(bar_number).first(3)
      HeadMusic::Style::Mark.for_all(opening) if static_point?(opening, bar_number)
    end
  end

  private

  # Read from the notes' own positions rather than beat numbers, so a half
  # beat in 3/2 is judged as a quarter beat is in 4/4.
  def static_point?(opening, bar_number)
    return false unless opening.length == 3

    first, second, third = opening
    first.position == downbeat_of(bar_number) &&
      undotted_quarter?(first) && undotted_quarter?(second) &&
      second.position == first.next_position && third.position == second.next_position &&
      third.rhythmic_duration.total_value >= half_value &&
      third.next_position == downbeat_of(bar_number + 1)
  end

  # A tied note is judged by its attack.
  def undotted_quarter?(note)
    attack = note.rhythmic_duration.values.first
    attack.unit_name == "quarter" && attack.dots.zero?
  end

  def half_value
    HeadMusic::Rudiment::RhythmicValue.get(:half).total_value
  end
end
