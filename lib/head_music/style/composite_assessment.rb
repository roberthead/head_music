# A module for style analysis and guidelines.
module HeadMusic::Style; end

# Several guides applied to one voice: the combined grade, and the per-guide
# assessments it was computed from.
#
# Answers the same protocol as GuideAssessment, which is the point -- a consumer
# walks `assessments` and never asks which of the two it is holding. The shared
# example group in spec/support is what keeps the two from drifting apart.
class HeadMusic::Style::CompositeAssessment
  attr_reader :guide, :voice

  def initialize(guide, voice)
    unless guide.respond_to?(:composite?) && guide.composite?
      raise ArgumentError, "guide must be a composite (got #{guide.inspect})"
    end

    @guide = guide
    @voice = voice
  end

  # Memoized because everything else here is derived from it: without this, each
  # of fitness, messages, and guide_item_assessments re-runs the whole member
  # analysis, and `assessments.first` is a different object every time.
  def assessments
    @assessments ||= guide.guides.map { |member| member.assess(voice) }
  end

  def guide_item_assessments
    @guide_item_assessments ||= assessments.flat_map(&:guide_item_assessments)
  end

  def messages
    assessments.flat_map(&:messages)
  end

  def adherent?
    assessments.all?(&:adherent?)
  end

  def assessable?
    assessments.all?(&:assessable?)
  end

  # Geometric rather than arithmetic, because a species grade is two grades that
  # must both hold. A perfect melody against a half-graded harmony reads 0.707
  # rather than 0.75, and either half at zero takes the whole grade to zero.
  # Acing the melody buys no relief from the harmony.
  #
  # When a member is unassessable the rubric is left out of it entirely. This is
  # GuideAssessment's own rule lifted one level -- "a voice failing a
  # precondition has not earned a bad grade on the rest" -- with the nouns
  # raised: the composite has not earned a grade on the OTHER MEMBERS either.
  # Without the branch, an assessable member's rubric leaks into a grade that was
  # never earned, moving it up or down according to material the guide declined
  # to look at.
  #
  # With today's registry the branch changes no number, and that is not an
  # argument against it. The members of a species composite share
  # MinimumNotes.with(3) and fail it identically, and the only gate that
  # distinguishes them, SetAgainstAnotherVoice, scores exactly 0 or 1 -- so a
  # solo voice grades 0.0 either way. The rules part company where the members'
  # gates differ and one scores a fraction, which MinimumNotes does. The rule is
  # chosen for what a gate means, not for a number it currently moves.
  def fitness
    @fitness ||= geometric_mean(
      assessable? ? assessments.map(&:fitness) : assessments.map(&:gate_factor)
    )
  end

  def gate_factor
    @gate_factor ||= geometric_mean(assessments.map(&:gate_factor))
  end

  # Grouped rather than keyed, so a composite of two guides sharing a category
  # reports both instead of silently dropping one. Follows fitness into the
  # gate-factor branch: a consumer showing melody, harmony, and total must not be
  # handed three numbers that do not combine.
  def fitness_by_category
    assessments.group_by { |assessment| assessment.guide.category }
      .transform_values { |group| geometric_mean(group.map(&method(:member_fitness))) }
  end

  private

  def member_fitness(assessment)
    assessable? ? assessment.fitness : assessment.gate_factor
  end

  # Exact where exactness is required, which the log-sum form would not be:
  # [1.0, 1.0] is exactly 1.0, which adherent? depends on, and any zero member is
  # exactly 0.0. The empty case cannot arise -- CompositeGuide refuses fewer than
  # two members -- so it is left to raise rather than answering a silent 1.0.
  def geometric_mean(values)
    values.reduce(:*)**(1.0 / values.length)
  end
end
