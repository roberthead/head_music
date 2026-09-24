# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline. Salzer and Schachter permit a unison off the
# downbeat "if tied over or followed by stepwise motion" (p. 106), and the
# opening unison is outside the rule (p. 40).
class HeadMusic::Style::Guidelines::StepOutOfUnison < HeadMusic::Style::Guideline
  def marks
    leaps_following_unisons.map do |note_pair|
      HeadMusic::Style::Mark.for_all(note_pair.notes)
    end.flatten
  end

  private

  def leaps_following_unisons
    melodic_note_pairs_following_unisons
      .select(&:leap?)
      .reject { |pair| opening?(pair.first_note) || tied_over?(pair.first_note) }
  end

  def opening?(note)
    note == first_note
  end

  def tied_over?(note)
    note.next_position > note.position.start_of_next_bar
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
