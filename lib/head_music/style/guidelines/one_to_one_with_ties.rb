# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline for fourth species counterpoint.
# For each cantus firmus note, verifies that one or two counterpoint notes
# are sounding at that position. A note may sustain across the barline
# (syncopation) rather than starting at the CF note position.
# Two notes sounding against one CF note is permitted as a "second species break."
class HeadMusic::Style::Guidelines::OneToOneWithTies < HeadMusic::Style::Annotation
  MESSAGE = "Place one note per cantus firmus note. Notes may sustain across the barline."

  def marks
    return unless cantus_firmus&.notes
    return if cantus_firmus.notes.empty?

    HeadMusic::Style::Mark.for_each(uncovered_cantus_firmus_notes)
  end

  private

  def uncovered_cantus_firmus_notes
    cantus_firmus.notes.select do |cf_note|
      notes_sounding = voice.notes_during(cf_note)
      notes_sounding.empty? || notes_sounding.length > 2
    end
  end
end
