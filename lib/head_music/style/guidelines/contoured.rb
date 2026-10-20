# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody without the configured contour
# Configure the contour with the factory, e.g. Contoured.with(:arch).
#
# Arch, valley, and wave are shapes, graded by the legs between the endpoints.
# Ascending and descending are directions, graded by the endpoints alone. Static
# is the level direction, graded by range. Each degree of miss costs φ⁻².
class HeadMusic::Style::Guidelines::Contoured < HeadMusic::Style::Guideline
  CONTOURS = %i[ascending descending arch valley wave static].freeze

  TREND_REVERSAL_SEMITONES = 3 # a leg must exceed a whole step

  REQUIRED_LEGS = {arch: %i[rise fall], valley: %i[fall rise]}.freeze
  DIRECTION_LEGS = {ascending: :rise, descending: :fall}.freeze
  WAVE_LEGS = 3

  LegMiss = Data.define(:extra, :missing)

  SHAPE_MISSES = %w[reversed_legs extra_legs missing_rise missing_fall missing_legs].freeze
  MISSES = {
    ascending: %w[ascending_rise ascending_start ascending_end ascending_start_and_end],
    descending: %w[descending_fall descending_start descending_end descending_start_and_end],
    arch: SHAPE_MISSES,
    valley: SHAPE_MISSES,
    wave: %w[missing_legs],
    static: []
  }.freeze

  # Running state for the zigzag walk in #legs.
  TrendWalk = Struct.new(:legs, :leg, :high, :low, :extreme)

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

    self.class.miss_key(DIRECTION_LEGS.key?(contour) ? direction_miss : shape_miss)
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
      elsif DIRECTION_LEGS.key?(contour)
        failed_endpoints.length
      else
        leg_miss.extra + leg_miss.missing
      end
  end

  # A wobble too small to make a leg is too small to spoil a direction, and a
  # net change too small to make a leg is too small to make one.
  def failed_endpoints
    @failed_endpoints ||= begin
      low, high = pitch_numbers.minmax
      sign, start, finish = (contour == :ascending) ? [1, low, high] : [-1, high, low]
      first, last = pitch_numbers.values_at(0, -1)
      [
        (:start unless near?(first, start)),
        (:end unless near?(last, finish)),
        (DIRECTION_LEGS.fetch(contour) if sign * (last - first) < TREND_REVERSAL_SEMITONES)
      ].compact
    end
  end

  # Failing to rise (or fall) is failing the direction itself, so it outranks
  # the endpoints.
  def direction_miss
    leg = DIRECTION_LEGS.fetch(contour)
    failed = failed_endpoints.include?(leg) ? [leg] : failed_endpoints
    "#{contour}_#{failed.join("_and_")}"
  end

  # Extra and missing legs together happen only for the mirror shape.
  def shape_miss
    if leg_miss.extra.positive?
      leg_miss.missing.positive? ? "reversed_legs" : "extra_legs"
    elsif leg_miss.missing == 1 && REQUIRED_LEGS.key?(contour)
      "missing_#{(REQUIRED_LEGS.fetch(contour) - legs).first}"
    else
      "missing_legs"
    end
  end

  def near?(number, extreme)
    (number - extreme).abs < TREND_REVERSAL_SEMITONES
  end

  # Legs alternate, so a lone leg always matches one end of a required pair,
  # and three or more always contain the pair.
  def leg_miss
    @leg_miss ||=
      if contour == :wave
        LegMiss.new(extra: 0, missing: [WAVE_LEGS - legs.length, 0].max)
      else
        required = REQUIRED_LEGS.fetch(contour)
        matched = legs.each_cons(required.length).include?(required) ? required.length : [legs.length, 1].min
        LegMiss.new(extra: legs.length - matched, missing: required.length - matched)
      end
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

  # A reversal counts only once the melody retraces TREND_REVERSAL_SEMITONES
  # from the running extreme, so neighbor-note undulation is not a new leg.
  def legs
    @legs ||= begin
      first = pitch_numbers.first
      walk = TrendWalk.new([], nil, first, first, nil)
      pitch_numbers.drop(1).each { |number| advance_leg(walk, number) }
      walk.legs
    end
  end

  def advance_leg(walk, number)
    if walk.leg.nil?
      seek_leg(walk, number)
    else
      continue_leg(walk, number)
    end
  end

  def seek_leg(walk, number)
    if number - walk.low >= TREND_REVERSAL_SEMITONES
      start_leg(walk, :rise, number)
    elsif walk.high - number >= TREND_REVERSAL_SEMITONES
      start_leg(walk, :fall, number)
    else
      walk.high = [walk.high, number].max
      walk.low = [walk.low, number].min
    end
  end

  def continue_leg(walk, number)
    sign = (walk.leg == :rise) ? 1 : -1
    delta = number - walk.extreme
    if sign * delta > 0
      walk.extreme = number
    elsif -sign * delta >= TREND_REVERSAL_SEMITONES
      start_leg(walk, opposite_leg(walk.leg), number)
    end
  end

  def start_leg(walk, leg, number)
    walk.leg = leg
    walk.extreme = number
    walk.legs << leg
  end

  def opposite_leg(leg)
    (leg == :rise) ? :fall : :rise
  end
end
