# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a voice with no companion to be set against: without this the harmonic
# guidelines reach for a cantus firmus that is not there and raise mid-grading.
#
# Named for what it checks. Guideline's cantus_firmus is the voice marked as one
# or else the first other voice, so HasCantusFirmus would claim more.
class HeadMusic::Style::Guidelines::SetAgainstAnotherVoice < HeadMusic::Style::Guideline
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
