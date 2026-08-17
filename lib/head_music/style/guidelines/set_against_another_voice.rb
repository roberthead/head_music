# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a voice with no companion to be set against.
#
# The definitional precondition of a harmony guide: counterpoint is a
# relationship between voices, and a voice alone in its composition has no
# harmony to assess. Without this, the harmonic guidelines reach for a cantus
# firmus that is not there and raise mid-grading.
#
# Named for what it checks rather than for what it usually finds. Guideline's
# cantus_firmus is the companion marked as one *or else the first other voice*,
# so this passes for any companion that sounds -- HasCantusFirmus would claim
# more than it verifies.
class HeadMusic::Style::Guidelines::SetAgainstAnotherVoice < HeadMusic::Style::Guideline
  MESSAGE = "Set this voice against another voice."

  def marks
    return if companion_sounds?
    return no_placements_mark if placements.empty?

    HeadMusic::Style::Mark.for_all(placements, fitness: 0)
  end

  private

  def companion_sounds?
    !!cantus_firmus&.notes&.any?
  end
end
