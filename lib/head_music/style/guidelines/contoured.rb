# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody without the configured contour
# Configure the contour with the factory, e.g. Contoured.with(:arch).
class HeadMusic::Style::Guidelines::Contoured < HeadMusic::Style::Guideline
  CONTOURS = %i[ascending descending arch valley wave static].freeze

  TREND_REVERSAL_SEMITONES = 3 # a leg must exceed a whole step

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

  def arch?
    legs == %i[rise fall]
  end

  def valley?
    legs == %i[fall rise]
  end

  def wave?
    legs.length >= 3
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
