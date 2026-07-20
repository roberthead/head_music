# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody without the configured contour
# Configure the contour with the factory, e.g. Contoured.with(:arch).
class HeadMusic::Style::Guidelines::Contoured < HeadMusic::Style::Annotation
  CONTOURS = %i[ascending descending arch valley wave static].freeze

  TREND_REVERSAL_SEMITONES = 3 # a trend reversal must exceed a whole step

  # Running state for the zigzag walk in #trend_directions.
  TrendWalk = Struct.new(:directions, :direction, :high, :low, :extreme)

  DEFAULT_WEIGHT = HeadMusic::GOLDEN_RATIO_INVERSE

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

  def self.default_weight
    DEFAULT_WEIGHT
  end

  def marks
    return if notes.empty? || matches_contour?

    HeadMusic::Style::Mark.for_all(notes, fitness: HeadMusic::GOLDEN_RATIO_INVERSE**2)
  end

  def message
    "Write a melody with the #{contour} contour."
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

  # The climax is by definition the maximum, so "net rise before, net fall after"
  # is equivalent to both endpoints sitting below the climax pitch.
  # Climax uniqueness and consonance remain ConsonantClimax's job.
  def arch?
    endpoints_interior_to?(highest_pitch)
  end

  def valley?
    endpoints_interior_to?(lowest_pitch)
  end

  # Because the given pitch is a running extreme (the highest or lowest), no
  # endpoint can pass it, so "interior" simply means neither endpoint touches it.
  def endpoints_interior_to?(extreme_pitch)
    notes.length >= 3 && first_note.pitch != extreme_pitch && last_note.pitch != extreme_pitch
  end

  def wave?
    trend_directions.length >= 3
  end

  def static?
    range <= HeadMusic::Analysis::DiatonicInterval.get(:major_third) && !directional_endpoints?
  end

  # The highest_pitch > lowest_pitch guard is load-bearing: without it, an
  # all-same-pitch melody (first == lowest and last == highest simultaneously)
  # would absurdly fail static.
  def directional_endpoints?
    highest_pitch > lowest_pitch && (ascending? || descending?)
  end

  def pitch_numbers
    @pitch_numbers ||= notes.map { |note| note.pitch.midi_note_number }
  end

  # Zigzag walk: a trend reversal is confirmed only when the melody retraces at
  # least TREND_REVERSAL_SEMITONES from the running extreme of the current trend,
  # so stepwise neighbor-note undulation never registers as a trend change.
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

  # No trend confirmed yet: widen the running range until the melody breaks out
  # of it by at least the reversal threshold, which sets the first direction.
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

  # Within a trend: extend the extreme while the melody keeps going, or confirm a
  # reversal once it retraces from that extreme by at least the threshold.
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
