# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody without the configured contour
# Configure the contour with the factory, e.g. Contoured.with(:arch).
class HeadMusic::Style::Guidelines::Contoured < HeadMusic::Style::Guideline
  CONTOURS = %i[ascending descending arch valley wave static].freeze

  TREND_REVERSAL_SEMITONES = 3 # a trend reversal must exceed a whole step

  # Running state for the zigzag walk in #trend_directions.
  TrendWalk = Struct.new(:directions, :direction, :high, :low, :extreme)

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

  def marks
    return if notes.empty? || matches_contour?

    HeadMusic::Style::Mark.for_all(notes, fitness: HeadMusic::GOLDEN_RATIO_INVERSE**2)
  end

  def self.template_values(config)
    {contour: HeadMusic::Style::Template.render("contours.#{normalized_contour(config.fetch(:contour))}")}
  end

  private

  # Validated again here because Contoured.new(voice, contour: :bogus) bypasses .with.
  def contour
    @contour ||= self.class.normalized_contour(options.fetch(:contour))
  end

  def matches_contour?
    send("#{contour}?")
  end

  def ascending?
    first_note.pitch == lowest_pitch && last_note.pitch == highest_pitch
  end

  def descending?
    first_note.pitch == highest_pitch && last_note.pitch == lowest_pitch
  end

  # The climax is the maximum by definition, so "rise then fall" reduces to both
  # endpoints sitting below it. Uniqueness and consonance are ConsonantClimax's.
  def arch?
    endpoints_interior_to?(highest_pitch)
  end

  def valley?
    endpoints_interior_to?(lowest_pitch)
  end

  # The pitch is a running extreme, so no endpoint can pass it and "interior"
  # means neither endpoint touches it.
  def endpoints_interior_to?(extreme_pitch)
    notes.length >= 3 && first_note.pitch != extreme_pitch && last_note.pitch != extreme_pitch
  end

  def wave?
    trend_directions.length >= 3
  end

  def static?
    range <= HeadMusic::Analysis::DiatonicInterval.get(:major_third) && !directional_endpoints?
  end

  # The range guard is load-bearing: an all-same-pitch melody is simultaneously
  # ascending and descending, and would otherwise fail static.
  def directional_endpoints?
    highest_pitch > lowest_pitch && (ascending? || descending?)
  end

  def pitch_numbers
    @pitch_numbers ||= notes.map { |note| note.pitch.midi_note_number }
  end

  # A reversal counts only once the melody retraces TREND_REVERSAL_SEMITONES
  # from the running extreme, so neighbor-note undulation is not a trend change.
  def trend_directions
    @trend_directions ||= begin
      first = pitch_numbers.first
      walk = TrendWalk.new([], nil, first, first, nil)
      pitch_numbers.drop(1).each { |number| advance_trend(walk, number) }
      walk.directions
    end
  end

  def advance_trend(walk, number)
    if walk.direction.nil?
      seek_trend(walk, number)
    else
      continue_trend(walk, number)
    end
  end

  def seek_trend(walk, number)
    if number - walk.low >= TREND_REVERSAL_SEMITONES
      start_trend(walk, :ascending, number)
    elsif walk.high - number >= TREND_REVERSAL_SEMITONES
      start_trend(walk, :descending, number)
    else
      walk.high = [walk.high, number].max
      walk.low = [walk.low, number].min
    end
  end

  def continue_trend(walk, number)
    sign = (walk.direction == :ascending) ? 1 : -1
    delta = number - walk.extreme
    if sign * delta > 0
      walk.extreme = number
    elsif -sign * delta >= TREND_REVERSAL_SEMITONES
      start_trend(walk, opposite_direction(walk.direction), number)
    end
  end

  def start_trend(walk, direction, number)
    walk.direction = direction
    walk.extreme = number
    walk.directions << direction
  end

  def opposite_direction(direction)
    (direction == :ascending) ? :descending : :ascending
  end
end
