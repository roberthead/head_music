# frozen_string_literal: true

# Module for Annotations.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::StartOnTonic < HeadMusic::Style::Annotation
  MESSAGE = 'Start on the first scale degree.'

  def marks
    HeadMusic::Style::Mark.for(first_note) if first_note && !starts_on_tonic?
  end
end
