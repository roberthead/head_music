module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::ConsonantClimax < HeadMusic::Style::Annotation
  def message
    "Peak on a consonant high note one time."
  end

  def marks
    if notes
      improper_climaxes = highest_notes.select.with_index do |note, i|
        tonic_pitch = HeadMusic::Pitch.get(composition.key_signature.tonic_spelling)
        interval = HeadMusic::FunctionalInterval.new(tonic_pitch, note.pitch)
        interval.consonance.dissonant? || i > 0
      end
      HeadMusic::Style::Mark.for_each(improper_climaxes)
    end
  end
end
