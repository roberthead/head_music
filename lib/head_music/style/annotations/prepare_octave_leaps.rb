# frozen_string_literal: true

module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::PrepareOctaveLeaps < HeadMusic::Style::Annotation
  MESSAGE = 'Enter and exit an octave leap from within.'

  def marks
    (external_entries + external_exits).map do |trouble_spot|
      HeadMusic::Style::Mark.for_all(trouble_spot)
    end
  end

  private

  def external_entries
    melodic_intervals.map.with_index do |melodic_interval, i|
      if melodic_interval.octave? && i > 0 && !melodic_interval.spans?(notes[i - 1].pitch)
        notes[[i - 1, 0].max..(i + 1)]
      end
    end.compact
  end

  def external_exits
    melodic_intervals.map.with_index do |melodic_interval, i|
      if melodic_interval.octave? && (i == (melodic_intervals.length - 1) || !melodic_interval.spans?(notes[i + 2].pitch))
        notes[i..[i + 2, notes.length - 1].min]
      end
    end.compact
  end
end
