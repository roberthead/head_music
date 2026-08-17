# Module for guides
module HeadMusic::Style::Guides; end

# A free diatonic melody targeting a specific contour. Configured rather than
# subclassed: ContourMelody.with(contour: :arch, minimum_melodic_intervals: 2).
#
# Deliberately NOT a subclass of DiatonicMelody. Its lists are reached
# fully-qualified below instead, so nothing about this guide is inherited by
# accident -- the same reason it did not subclass when the ruleset was a
# constant.
class HeadMusic::Style::Guides::ContourMelody < HeadMusic::Style::Guides::SpeciesMelody
  # The non-gate peers of a contour guide share phi^-2 of rubric weight, so that
  # with Contoured at its default weight of phi^-1 (and phi^-1 + phi^-2 = 1), a
  # wrong contour on an otherwise perfect line grades exactly phi^-1.
  PEER_WEIGHT_BUDGET = HeadMusic::GOLDEN_RATIO_INVERSE**2

  # Normalizes eagerly so an invalid contour raises HERE, at configuration
  # time, rather than at analysis. Required keyword, so an omitted or
  # misspelled option name raises too.
  def self.with(contour:, minimum_melodic_intervals: nil)
    super(
      contour: HeadMusic::Style::Guidelines::Contoured.normalized_contour(contour),
      minimum_melodic_intervals: minimum_melodic_intervals
    )
  end

  # Guide.get passes through anything answering analyze, so naming this class
  # instead of a registry key reaches GuideAssessment and would otherwise fail
  # with a bare "missing keyword: :contour" as the lists are read, before any
  # guideline is built. Now that the six contour subclasses are gone, that is
  # the likeliest way to hold this wrong, so the error names both ways to hold
  # it right.
  def self.analyze(voice)
    raise ArgumentError,
      "#{name} requires configuration. " \
      "Use #{name}.with(contour: :arch, minimum_melodic_intervals: 2) " \
      'or HeadMusic::Style::Guide.get("arch_contour_melody").'
  end

  # The keyword signature is the declaration: a guide whose lists depend on
  # configuration overrides the reader rather than declaring in the class body,
  # and the arity is what .with checks to decide the guide is configurable.
  #
  # Demotion is the whole design. Everything DiatonicMelody teaches is
  # background here, and the contour is the lesson -- the partition and
  # re-weighting this guide used to compute by hand.
  def self.items_by_tier(contour:, minimum_melodic_intervals: nil)
    peers = HeadMusic::Style::Guides::DiatonicMelody.primary_items
    peer_weight = PEER_WEIGHT_BUDGET / peers.length
    motion_gate =
      minimum_melodic_intervals &&
      HeadMusic::Style::Guidelines::MinimumMelodicIntervals.with(minimum_melodic_intervals)

    normalize(
      gate: [*HeadMusic::Style::Guides::DiatonicMelody.gate_items, motion_gate],
      primary: [HeadMusic::Style::Guidelines::Contoured.with(contour)],
      secondary: peers.map { |item| item.with(weight: peer_weight) }
    )
  end
end
