# Guidelines for a free diatonic melody (not bound to cantus firmus start/end constraints).
class HeadMusic::Style::Guides::DiatonicMelody < HeadMusic::Style::Guides::SpeciesMelody
  # Modern interpretation: major sixths are singable; sevenths are not.
  SINGABLE_INTERVALS = %w[P1 m2 M2 m3 M3 P4 P5 m6 M6 P8].freeze

  RULESET = [
    *(MELODIC_CORE - [HeadMusic::Style::Guidelines::SingableIntervals]),
    HeadMusic::Style::Guidelines::SingableIntervals.with(
      ascending: SINGABLE_INTERVALS,
      descending: SINGABLE_INTERVALS
    ),
    HeadMusic::Style::Guidelines::ModerateDirectionChanges,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::LargeLeaps.with(
      minimum: :perfect_fourth,
      recovery: %i[consonant_triad any_step repetition opposite_leap_within]
    ),
    HeadMusic::Style::Guidelines::MinimumNotes.with(5),
    HeadMusic::Style::Guidelines::MaximumNotes.with(32)
  ].freeze

  # The non-gate peers of a contour guide share phi^-2 of rubric weight, so
  # that with Contoured at its default weight of phi^-1 (and phi^-1 + phi^-2
  # = 1), a wrong contour on an otherwise perfect line grades exactly phi^-1.
  CONTOUR_PEER_WEIGHT_BUDGET = HeadMusic::GOLDEN_RATIO_INVERSE**2

  # Builds a contour guide's ruleset from this guide's rules: gate entries
  # pass through unchanged, non-gate peers split the peer weight budget
  # evenly, and the contour guideline is appended at its own default weight.
  # An optional motion gate excludes non-attempts (nil omits it, so a static
  # contour can legitimately repeat a single pitch).
  def self.contour_ruleset(contour_key, minimum_melodic_intervals: nil)
    gates, peers = RULESET.partition(&:default_gate?)
    peer_weight = CONTOUR_PEER_WEIGHT_BUDGET / peers.length
    motion_gate =
      minimum_melodic_intervals &&
      HeadMusic::Style::Guidelines::MinimumMelodicIntervals.with(minimum_melodic_intervals)
    [
      *gates,
      motion_gate,
      *peers.map { |rule| rule.with(weight: peer_weight) },
      HeadMusic::Style::Guidelines::Contoured.with(contour_key)
    ].compact.freeze
  end
end
