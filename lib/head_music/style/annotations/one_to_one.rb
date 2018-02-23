# frozen_string_literal: true

# Module for Annotations.
module HeadMusic::Style::Annotations; end

# A counterpoint guideline
class HeadMusic::Style::Annotations::OneToOne < HeadMusic::Style::Annotation
  MESSAGE = 'Place a note for each note in the other voice.'

  def marks
    return unless cantus_firmus&.notes
    return if cantus_firmus.notes.empty?
    HeadMusic::Style::Mark.for_each(
      notes_without_match(voice, cantus_firmus) + notes_without_match(cantus_firmus, voice)
    )
  end

  private

  def notes_without_match(voice1, voice2)
    voice1.notes.reject do |voice1_note|
      voice2.notes.map(&:position).include?(voice1_note.position)
    end
  end
end
