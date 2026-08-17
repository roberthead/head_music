# A Guideline is one rule of craft. Subclasses find faults in a voice and
# report them as marks.
#
# The class is the rule; instances are the analysis context that finds it,
# private to .assess. What a consumer holds is the GuideItemAssessment that
# comes back.
class HeadMusic::Style::Guideline
  MESSAGE = "Write music."

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

  # Pairs this guideline with the configuration a guide gives it,
  # e.g. MinimumNotes.with(5).
  def self.with(**options)
    HeadMusic::Style::GuideItem.new(self, options)
  end

  # The analysis seam. The instance built here is the analysis context -- it
  # memoizes intermediate work across the private predicates a guideline is
  # written from -- and it does not escape: what comes back is a frozen record
  # of what was found.
  def self.assess(voice, guide_item, tier)
    analyzer = new(voice, **guide_item.config)
    HeadMusic::Style::GuideItemAssessment.new(
      voice: voice,
      guide_item: guide_item,
      tier: tier,
      marks: analyzer.marks,
      fitness: analyzer.fitness,
      message: analyzer.message
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

  def message
    self.class::MESSAGE
  end

  def first_note
    notes.first
  end

  def last_note
    notes.last
  end

  # Signpost rather than enforcement -- send and allocate still reach it,
  # and a spec testing a guideline's internal reasoning legitimately does.
  # The guarantee that matters is that .assess is the only caller in lib.
  private_class_method :new

  protected

  attr_reader :options

  # Marks may be a single mark, an array, or nil depending on the guideline;
  # normalizing here keeps fitness and position scans uniform.
  def flattened_marks
    [marks].flatten.compact
  end

  # An empty voice has nowhere to put a mark, so a guideline that must fail it
  # marks the opening bar instead. Without this, Mark.for_all([]) returns no
  # marks at all and no marks means a fitness of 1.0 -- which is the mechanism
  # behind an empty voice grading perfectly.
  def no_placements_mark
    HeadMusic::Style::Mark.new(
      HeadMusic::Content::Position.new(composition, "1:1"),
      HeadMusic::Content::Position.new(composition, "2:1"),
      fitness: 0
    )
  end

  # Normalization rate for the product of mark fitnesses. Subclasses override
  # (e.g. with an opportunity count) to score by violation rate rather than
  # raw violation count. The default of 1 preserves the raw product.
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

  # Keeps only intervals where both voices actually sound, dropping any where
  # one voice is silent (fewer than two notes).
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
