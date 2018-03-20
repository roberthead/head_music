# frozen_string_literal: true

# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::AvoidOverlappingVoices < HeadMusic::Style::Annotation
  MESSAGE = 'Avoid overlapping voices. Maintain the high-low relationship between voices even for adjacent notes.'

  def marks
    overlappings
  end

  private

  def overlappings
    overlappings_of_lower_voices + overlappings_of_higher_voices
  end

  def overlappings_of_lower_voices
    overlappings_for_voices(lower_voices, :>)
  end

  def overlappings_of_higher_voices
    overlappings_for_voices(higher_voices, :<)
  end

  def overlappings_for_voices(voices, comparison_operator)
    [].tap do |marks|
      voices.each do |a_voice|
        overlapped_notes = overlappings_with_voice(a_voice, comparison_operator)
        marks << HeadMusic::Style::Mark.for_each(overlapped_notes)
      end
    end.flatten.compact
  end

  def overlappings_with_voice(other_voice, comparison_operator)
    voice.notes.drop(1).select do |note|
      preceding_note = other_voice.note_preceding(note.position)
      following_note = other_voice.note_following(note.position)
      preceding_note&.pitch&.send(comparison_operator, note.pitch) ||
        following_note&.pitch&.send(comparison_operator, note.pitch)
    end
  end
end
