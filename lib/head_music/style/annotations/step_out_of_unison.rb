# frozen_string_literal: true

module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::StepOutOfUnison < HeadMusic::Style::Annotation
  MESSAGE = 'Exit a unison by step.'

  def marks
    leaps_following_unisons.map do |skip|
      HeadMusic::Style::Mark.for_all(skip.notes)
    end.flatten
  end

  private

  def leaps_following_unisons
    melodic_intervals_following_unisons.select(&:leap?)
  end

  def melodic_intervals_following_unisons
    @melodic_intervals_following_unisons ||=
      perfect_unisons.map do |unison|
        note1 = voice.note_at(unison.position)
        note2 = voice.note_following(unison.position)
        HeadMusic::MelodicInterval.new(note1, note2) if note1 && note2
      end.compact
  end

  def perfect_unisons
    @unisons ||= harmonic_intervals.select(&:perfect_consonance?).select(&:unison?)
  end
end
