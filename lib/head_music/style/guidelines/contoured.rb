# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody without the configured contour
# Configure the contour with the factory, e.g. Contoured.with(:arch).
#
# Arch, valley, and wave are shapes, graded by the legs between the endpoints.
# Ascending and descending are directions, graded by the endpoints and the
# headway between them. Static is the level direction, graded by range. Each degree of miss costs φ⁻².
class HeadMusic::Style::Guidelines::Contoured < HeadMusic::Style::Guideline
  CONTOURS = %i[ascending descending arch valley wave static].freeze

  TREND_REVERSAL_SEMITONES = 3 # a leg must exceed a whole step

  SHAPE_MISSES = %w[reversed_legs extra_legs missing_rise missing_fall missing_legs].freeze
  MISSES = {
    ascending: %w[ascending_rise ascending_retrace ascending_start ascending_end ascending_start_and_end],
    descending: %w[descending_fall descending_retrace descending_start descending_end descending_start_and_end],
    arch: SHAPE_MISSES,
    valley: SHAPE_MISSES,
    wave: %w[too_few_legs],
    static: []
  }.freeze

  def self.with(contour_key, **options)
    super(contour: normalized_contour(contour_key), **options)
  end

  def self.normalized_contour(contour_key)
    contour = contour_key.to_s.downcase.to_sym
    unless CONTOURS.include?(contour)
      raise ArgumentError, "Contour must be one of: #{CONTOURS.join(", ")} (got #{contour_key.inspect})"
    end

    contour
  end

  def self.violation_keys(config = {})
    super + MISSES.fetch(normalized_contour(config.fetch(:contour))).map { |miss| miss_key(miss) }
  end

  def self.miss_key(miss) = "guidelines.#{template_key}.violations.#{miss}"

  # .assess asks adherent voices too, and static has one way to miss.
  def violation_key
    return super if notes.empty? || degree.zero? || contour == :static

    self.class.miss_key(reading.miss)
  end

  def marks
    return if notes.empty? || degree.zero?

    HeadMusic::Style::Mark.for_all(notes, fitness: HeadMusic::GOLDEN_RATIO_INVERSE**(2 * degree))
  end

  def self.template_values(config)
    {contour: HeadMusic::Style::Template.render("contours.#{normalized_contour(config.fetch(:contour))}")}
  end

  private

  # Validated again here because Contoured.new(voice, contour: :bogus) bypasses .with.
  def contour
    @contour ||= self.class.normalized_contour(options.fetch(:contour))
  end

  def degree
    @degree ||=
      if contour == :static
        static? ? 0 : 1
      else
        reading.degree
      end
  end

  def reading
    @reading ||= reading_class.new(contour, pitch_numbers)
  end

  def reading_class
    DirectionReading::DIRECTION_LEGS.key?(contour) ? DirectionReading : ShapeReading
  end

  def static?
    range <= HeadMusic::Analysis::DiatonicInterval.get(:major_third) && !directional_endpoints?
  end

  # Strict, unlike the directions: within a major third, their tolerance would
  # call nearly every melody directional. The range guard is load-bearing: an
  # all-same-pitch melody has the lowest and highest pitch at both ends, and
  # would otherwise fail static.
  def directional_endpoints?
    highest_pitch > lowest_pitch &&
      [first_note.pitch, last_note.pitch].minmax == [lowest_pitch, highest_pitch]
  end

  def pitch_numbers
    @pitch_numbers ||= notes.map { |note| note.pitch.midi_note_number }
  end
end
