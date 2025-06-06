# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::StepOutOfUnison < HeadMusic::Style::Annotation
  MESSAGE = "Exit a unison by step."

  def marks
    leaps_following_unisons.map do |note_pair|
      HeadMusic::Style::Mark.for_all(note_pair.notes)
    end.flatten
  end

  private

  def leaps_following_unisons
    melodic_note_pairs_following_unisons.select(&:leap?)
  end

  def melodic_note_pairs_following_unisons
    @melodic_note_pairs_following_unisons ||=
      perfect_unisons.map do |unison|
        note1 = voice.note_at(unison.position)
        note2 = voice.note_following(unison.position)
        HeadMusic::Content::Voice::MelodicNotePair.new(note1, note2) if note1 && note2
      end.compact
  end

  def perfect_unisons
    @perfect_unisons ||= harmonic_intervals.select(&:perfect_consonance?).select(&:unison?)
  end
end
