# frozen_string_literal: true

module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::StartOnTonic < HeadMusic::Style::Annotation
  MESSAGE = 'Start on the first scale degree.'

  def marks
    HeadMusic::Style::Mark.for(first_note) if first_note && !starts_on_tonic?
  end
end
