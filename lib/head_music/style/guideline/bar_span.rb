module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # The voice's own bars, rather than the cantus firmus's, so a solo line is
  # judged over its bars too.
  module BarSpan
    protected

    def first_bar_number
      notes.first.position.bar_number
    end

    def last_bar_number
      notes.last.position.bar_number
    end

    def middle_bar_numbers
      ((first_bar_number + 1)...last_bar_number).to_a
    end

    def body_bar_numbers
      (first_bar_number...last_bar_number).to_a
    end

    def downbeat_of(bar_number)
      HeadMusic::Content::Position.new(flow, "#{bar_number}:1")
    end

    def notes_in_bar(bar_number)
      notes.select { |note| note.position.bar_number == bar_number }
    end

    def mark_bar(bar_number)
      bar_notes = notes_in_bar(bar_number)
      return HeadMusic::Style::Mark.for_all(bar_notes) if bar_notes.any?

      HeadMusic::Style::Mark.new(downbeat_of(bar_number), downbeat_of(bar_number + 1))
    end
  end
end
