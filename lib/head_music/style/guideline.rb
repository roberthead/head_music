# A Guideline is one rule of craft: subclasses find faults in a voice and
# report them as marks. The class is the rule; instances are the analysis
# context, private to .assess, which returns a frozen GuideItemAssessment.
#
# The rule's own work -- marks and the fitness they add up to -- is here. What
# a subclass reads to do that work comes from the context mixins, what the
# rule says about a fault comes from Wording, and how much it weighs against
# its siblings comes from Strength.
class HeadMusic::Style::Guideline
  extend HeadMusic::Style::Guideline::Wording
  extend HeadMusic::Style::Guideline::Strength

  include HeadMusic::Style::Guideline::VoiceContext
  include HeadMusic::Style::Guideline::HarmonicContext
  include HeadMusic::Style::Guideline::MelodicContext

  attr_reader :voice

  delegate(
    :composition,
    :highest_pitch,
    :lowest_pitch,
    :highest_notes,
    :lowest_notes,
    :melodic_note_pairs,
    :melodic_intervals,
    :notes,
    :notes_not_in_key,
    :placements,
    :range,
    :rests,
    to: :voice
  )

  delegate :key_signature, to: :composition
  delegate :tonic_spelling, to: :key_signature

  def initialize(voice, **options)
    @voice = voice
    @options = options
  end

  # Strength rides beside the configuration rather than inside it: config is
  # splatted into the analyzer, returned as an I18n interpolation value, and --
  # worst -- decides item equality, so an overridden ApproachPerfectionContrarily
  # inside config would fall out of the core-membership partition and be graded
  # as a taught rule at full primary weight.
  def self.with(strength: nil, **options)
    HeadMusic::Style::GuideItem.new(self, options, strength: strength)
  end

  def self.assess(voice, guide_item, tier)
    analyzer = new(voice, **guide_item.config)
    HeadMusic::Style::GuideItemAssessment.new(
      voice: voice,
      guide_item: guide_item,
      tier: tier,
      marks: analyzer.marks,
      fitness: analyzer.fitness,
      violation_key: analyzer.violation_key,
      violation_values: analyzer.violation_values
    )
  end

  def fitness
    mark_fitnesses = flattened_marks.map(&:fitness)
    return 1.0 if mark_fitnesses.empty?

    mark_fitnesses.reduce(1, :*)**(1.0 / [fitness_denominator, 1].max)
  end

  def adherent?
    fitness == 1
  end

  def has_notes?
    !!first_note
  end

  def start_position
    flattened_marks.map(&:start_position).min
  end

  def end_position
    flattened_marks.map(&:end_position).max
  end

  # Decided during analysis, so a guideline with more than one way to fail
  # names the one it found -- see ConsonantClimax.
  def violation_key
    self.class.violation_key(options)
  end

  # Only what this violation adds. The item's own interpolations are rebuilt at
  # render time, so an assessment made under one locale reads right in another.
  def violation_values
    {}
  end

  # Signpost rather than enforcement: send still reaches it, and specs do. The
  # guarantee that matters is that .assess is the only caller in lib.
  private_class_method :new

  protected

  attr_reader :options

  # Marks may be one, many, or nil depending on the guideline.
  def flattened_marks
    [marks].flatten.compact
  end

  # An empty voice has nowhere to put a mark, and no marks means a fitness of
  # 1.0 -- which is how an empty voice used to grade perfectly.
  def no_placements_mark
    HeadMusic::Style::Mark.new(
      HeadMusic::Content::Position.new(composition, "1:1"),
      HeadMusic::Content::Position.new(composition, "2:1"),
      fitness: 0
    )
  end

  # Subclasses override with an opportunity count to score by violation rate
  # rather than raw count.
  def fitness_denominator
    1
  end
end
