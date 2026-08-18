# A Guideline is one rule of craft: subclasses find faults in a voice and
# report them as marks. The class is the rule; instances are the analysis
# context, private to .assess, which returns a frozen GuideItemAssessment.
class HeadMusic::Style::Guideline
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

  def self.with(**options)
    HeadMusic::Style::GuideItem.new(self, options)
  end

  # Addressed in the locale files by the snake_case of the class name, so a new
  # guideline needs no declaration.
  def self.template_key
    @template_key ||= HeadMusic::Utilities::Case.to_snake_case(name.split("::").last)
  end

  def self.name_key = "guidelines.#{template_key}.name"

  def self.instruction_key = "guidelines.#{template_key}.instruction"

  # Takes the configuration: a guide may name a different template.
  def self.violation_key(_config = {}) = "guidelines.#{template_key}.violations.default"

  # Where a locale has nothing to say, the class name read as a sentence beats
  # nothing.
  def self.render_name(config)
    return template_key.tr("_", " ").capitalize unless HeadMusic::Style::Template.exists?(name_key)

    render_template(name_key, config)
  end

  # Violations are already phrased imperatively, so a guideline with nothing
  # more specific to say instructs with the sentence it would complain with.
  def self.render_instruction(config)
    return render_violation(config) unless HeadMusic::Style::Template.exists?(instruction_key)

    render_template(instruction_key, config)
  end

  def self.render_violation(config)
    render_template(violation_key(config), config)
  end

  # Every key an analysis can choose between, not only the one a bare config
  # names. Load-time verification renders all of them: a branch reached by one
  # kind of failure is otherwise unrendered until a student causes it.
  def self.violation_keys(config = {})
    [violation_key(config)]
  end

  def self.render_violations(config)
    violation_keys(config).map { |key| render_template(key, config) }
  end

  # Takes the configuration rather than finished values, so template_values --
  # where numbers humanize -- runs inside the locale the sentence renders in.
  def self.render_template(key, config, extra_values = {})
    HeadMusic::Style::Template.in_locale_of(key) do
      values = template_values(config).merge(extra_values)
      if values.key?(:count)
        HeadMusic::Style::Template.pluralize(key, **values)
      else
        HeadMusic::Style::Template.render(key, **values)
      end
    end
  end

  # Not the config itself: seven items declare none and read their values from
  # class constants, and I18n returns a template untouched when given no values.
  def self.template_values(config)
    config.except(:violation_key)
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

  def first_note
    notes.first
  end

  def last_note
    notes.last
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

  def voices
    @voices ||= voice.composition.voices
  end

  def other_voices
    @other_voices ||= voices.reject { |part| part == voice }
  end

  def cantus_firmus
    @cantus_firmus ||= other_voices.detect(&:cantus_firmus?) || other_voices.first
  end

  def higher_voices
    @higher_voices ||= unsorted_higher_voices.sort_by(&:highest_pitch).reverse
  end

  def lower_voices
    @lower_voices ||= unsorted_lower_voices.sort_by(&:lowest_pitch).reverse
  end

  def diatonic_interval_from_tonic(note)
    tonic_to_use = tonic_pitch
    tonic_to_use -= HeadMusic::Rudiment::ChromaticInterval.get(:perfect_octave) while tonic_to_use > note.pitch
    HeadMusic::Analysis::DiatonicInterval.new(tonic_to_use, note.pitch)
  end

  def bass_voice?
    lower_voices.empty?
  end

  def starts_on_tonic?
    tonic_spelling == first_note.spelling
  end

  def motions
    downbeat_harmonic_intervals.each_cons(2).map do |harmonic_interval_pair|
      HeadMusic::Analysis::Motion.new(*harmonic_interval_pair)
    end
  end

  def downbeat_harmonic_intervals
    @downbeat_harmonic_intervals ||=
      sounding_together(
        cantus_firmus.notes.map { |note| HeadMusic::Analysis::HarmonicInterval.new(note.voice, voice, note.position) }
      )
  end

  def harmonic_intervals
    @harmonic_intervals ||=
      sounding_together(
        positions.map { |position| HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, position) }
      )
  end

  # Fewer than two notes means one voice is silent, so nothing sounds together.
  def sounding_together(intervals)
    intervals.reject { |interval| interval.notes.length < 2 }
  end

  def positions
    @positions ||=
      voices.map(&:notes).flatten.map(&:position).sort.uniq(&:to_s)
  end

  def unsorted_higher_voices
    other_voices.select { |part| part.highest_pitch && highest_pitch && part.highest_pitch > highest_pitch }
  end

  def unsorted_lower_voices
    other_voices.select { |part| part.lowest_pitch && lowest_pitch && part.lowest_pitch < lowest_pitch }
  end

  def tonic_pitch
    @tonic_pitch ||= HeadMusic::Rudiment::Pitch.get(tonic_spelling)
  end

  def preceding_note(note)
    index = notes.index(note)
    notes[index - 1] if index && index > 0
  end

  def following_note(note)
    index = notes.index(note)
    notes[index + 1] if index && index < notes.length - 1
  end
end
