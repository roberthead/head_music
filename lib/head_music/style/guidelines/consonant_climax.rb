# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::ConsonantClimax < HeadMusic::Style::Annotation
  MESSAGE = "Peak on a consonant high or low note one time or twice with a step between."

  def marks
    HeadMusic::Style::Mark.for_each(highest_notes) unless adherent_climax?
  end

  private

  def adherent_climax?
    descending_melody? ? adherent_low_pitch? : adherent_high_pitch?
  end

  def adherent_high_pitch?
    has_notes? && highest_pitch_consonant_with_tonic? &&
      (highest_pitch_appears_once? || highest_pitch_appears_twice_with_step_between?)
  end

  def adherent_low_pitch?
    has_notes? &&
      lowest_pitch_consonant_with_tonic? &&
      (lowest_pitch_appears_once? || lowest_pitch_appears_twice_with_step_between?)
  end

  def highest_pitch_consonant_with_tonic?
    !diatonic_interval_to_highest_pitch.dissonant?(:melodic)
  end

  def lowest_pitch_consonant_with_tonic?
    !diatonic_interval_to_lowest_pitch.dissonant?(:melodic)
  end

  def diatonic_interval_to_highest_pitch
    @diatonic_interval_to_highest_pitch ||=
      HeadMusic::Analysis::DiatonicInterval.new(tonic_pitch, highest_pitch)
  end

  def diatonic_interval_to_lowest_pitch
    @diatonic_interval_to_lowest_pitch ||=
      HeadMusic::Analysis::DiatonicInterval.new(tonic_pitch, lowest_pitch)
  end

  def highest_pitch_appears_once?
    highest_notes.length == 1
  end

  def lowest_pitch_appears_once?
    lowest_notes.length == 1
  end

  def highest_pitch_appears_twice_with_step_between?
    highest_pitch_appears_twice? &&
      single_note_between_highest_notes? &&
      step_between_highest_notes?
  end

  def lowest_pitch_appears_twice_with_step_between?
    lowest_pitch_appears_twice? &&
      single_note_between_lowest_notes? &&
      step_between_lowest_notes?
  end

  def highest_pitch_appears_twice?
    highest_notes.length == 2
  end

  def lowest_pitch_appears_twice?
    lowest_notes.length == 2
  end

  def step_between_highest_notes?
    HeadMusic::Analysis::MelodicInterval.new(highest_notes.first, notes_between_highest_notes.first).step?
  end

  def step_between_lowest_notes?
    HeadMusic::Analysis::MelodicInterval.new(lowest_notes.first, notes_between_lowest_notes.first).step?
  end

  def single_note_between_highest_notes?
    notes_between_highest_notes.length == 1
  end

  def single_note_between_lowest_notes?
    notes_between_lowest_notes.length == 1
  end

  def notes_between_highest_notes
    notes_between(highest_notes)
  end

  def notes_between_lowest_notes
    notes_between(lowest_notes)
  end

  def notes_between(edge_notes)
    indexes = edge_notes.map { |note| notes.index(note) }
    notes[(indexes.first + 1)..(indexes.last - 1)] || []
  end

  def descending_melody?
    # account for the possibility of opening with an octave leap
    notes.length > 1 &&
      [first_note.pitch, second_note.pitch].include?(highest_pitch) &&
      highest_pitch.spelling == tonic_spelling
  end

  def second_note
    notes && notes[1]
  end
end
