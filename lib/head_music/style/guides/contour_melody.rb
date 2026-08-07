# A free diatonic melody targeting a specific contour. Configured rather than
# subclassed: ContourMelody.with(contour: :arch, minimum_melodic_intervals: 2).
#
# Deliberately NOT a subclass of DiatonicMelody, even though it builds on that
# guide's ruleset. Ruby resolves ::RULESET up the ancestor chain, so inheriting
# from DiatonicMelody would leave ContourMelody::RULESET silently returning the
# plain diatonic ruleset -- no contour rule, no motion gate, unweighted peers,
# and a plausible-looking fitness. The ruleset is reached fully-qualified below
# instead, which keeps the constant genuinely absent here.
class HeadMusic::Style::Guides::ContourMelody < HeadMusic::Style::Guides::SpeciesMelody
  # The non-gate peers of a contour guide share phi^-2 of rubric weight, so that
  # with Contoured at its default weight of phi^-1 (and phi^-1 + phi^-2 = 1), a
  # wrong contour on an otherwise perfect line grades exactly phi^-1.
  PEER_WEIGHT_BUDGET = HeadMusic::GOLDEN_RATIO_INVERSE**2

  # Neither the partition nor the peer weight depends on configuration --
  # DiatonicMelody::RULESET is frozen -- so both stay at class-definition time.
  # Only the motion gate and the contour rule vary per option set, which is why
  # no options-keyed cache is needed.
  GATES, WEIGHTED_PEERS = begin
    gates, peers = HeadMusic::Style::Guides::DiatonicMelody::RULESET.partition(&:default_gate?)
    peer_weight = PEER_WEIGHT_BUDGET / peers.length
    [gates.freeze, peers.map { |rule| rule.with(weight: peer_weight) }.freeze]
  end

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
  # instead of a registry key reaches Analysis and would otherwise fail at the
  # first annotation with a bare "missing keyword: :contour". Now that the six
  # contour subclasses are gone, that is the likeliest way to hold this wrong,
  # so the error names both ways to hold it right.
  def self.analyze(voice)
    raise ArgumentError,
      "#{name} requires configuration. " \
      "Use #{name}.with(contour: :arch, minimum_melodic_intervals: 2) " \
      'or HeadMusic::Style::Guide.get("arch_contour_melody").'
  end

  # An optional motion gate excludes non-attempts; nil omits it, so a static
  # contour can legitimately repeat a single pitch.
  def self.ruleset(contour:, minimum_melodic_intervals: nil)
    motion_gate =
      minimum_melodic_intervals &&
      HeadMusic::Style::Guidelines::MinimumMelodicIntervals.with(minimum_melodic_intervals)
    [
      *GATES,
      motion_gate,
      *WEIGHTED_PEERS,
      HeadMusic::Style::Guidelines::Contoured.with(contour)
    ].compact.freeze
  end
end
