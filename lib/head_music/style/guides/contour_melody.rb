# Module for guides
module HeadMusic::Style::Guides; end

# A free diatonic melody targeting a specific contour. Configured rather than
# subclassed: ContourMelody.with(contour: :arch, minimum_melodic_intervals: 2).
#
# Deliberately not a subclass of DiatonicMelody, whose lists are reached
# fully-qualified below, so nothing is inherited by accident.
class HeadMusic::Style::Guides::ContourMelody < HeadMusic::Style::Guides::SpeciesMelody
  # Eager, so an invalid contour raises at configuration time rather than at
  # analysis. Required keyword, so a misspelled option name raises too.
  def self.with(contour:, minimum_melodic_intervals: nil)
    super(
      contour: HeadMusic::Style::Guidelines::Contoured.normalized_contour(contour),
      minimum_melodic_intervals: minimum_melodic_intervals
    )
  end

  # Guide.get passes through anything that assesses a voice, so naming this
  # class instead of a registry key would otherwise fail with a bare "missing
  # keyword: :contour". Both seams raise, so the message arrives either way.
  def self.assess(voice) = raise(ArgumentError, unconfigured_message)

  def self.assess_items(voice) = raise(ArgumentError, unconfigured_message)

  def self.unconfigured_message
    "#{name} requires configuration. " \
      "Use #{name}.with(contour: :arch, minimum_melodic_intervals: 2) " \
      'or HeadMusic::Style::Guide.get("arch_contour_melody").'
  end

  # The keyword signature is the declaration, and its arity is what .with
  # checks to decide the guide is configurable. Everything DiatonicMelody
  # teaches is background here; the contour is the lesson.
  def self.items_by_tier(contour:, minimum_melodic_intervals: nil)
    motion_gate =
      minimum_melodic_intervals &&
      HeadMusic::Style::Guidelines::MinimumMelodicIntervals.with(minimum_melodic_intervals)

    normalize(
      gate: [*HeadMusic::Style::Guides::DiatonicMelody.gate_items, motion_gate],
      primary: [HeadMusic::Style::Guidelines::Contoured.with(contour)],
      secondary: HeadMusic::Style::Guides::DiatonicMelody.primary_items
    )
  end
end
