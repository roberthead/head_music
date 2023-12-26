# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::Diatonic < HeadMusic::Style::Annotation
  MESSAGE = "Use only notes in the key signature."

  def marks
    HeadMusic::Style::Mark.for_each(notes_not_in_key_excluding_penultimate_leading_tone)
  end

  private

  def notes_not_in_key_excluding_penultimate_leading_tone
    notes_not_in_key.reject do |note|
      penultimate_note &&
        note == penultimate_note &&
        HeadMusic::ScaleDegree.new(key_signature, note.pitch.spelling).alteration == "#"
    end
  end

  def penultimate_note
    voice.note_preceding(positions.last) if positions.last
  end
end
