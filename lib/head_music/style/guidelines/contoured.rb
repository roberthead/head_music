# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody without the configured contour
# Configure the contour with the factory, e.g. Contoured.with(:arch).
class HeadMusic::Style::Guidelines::Contoured < HeadMusic::Style::Annotation
  CONTOURS = %i[ascending descending arch valley wave static].freeze

  TREND_REVERSAL_SEMITONES = 3 # a trend reversal must exceed a whole step

  def self.with(contour_key)
    contour = contour_key.to_s.downcase.to_sym
    unless CONTOURS.include?(contour)
      raise ArgumentError, "Contour must be one of: #{CONTOURS.join(", ")} (got #{contour_key.inspect})"
    end

    super(contour: contour)
  end

  def marks
    return if notes.empty? || matches_contour?

    HeadMusic::Style::Mark.for_all(notes)
  end

  def message
    "Write a melody with the #{contour} contour."
  end

  private

  # Validated again here because Contoured.new(voice, contour: :bogus) bypasses .with.
  def contour
    @contour ||= begin
      key = options.fetch(:contour)
      contour = key.to_s.downcase.to_sym
      unless CONTOURS.include?(contour)
        raise ArgumentError, "Contour must be one of: #{CONTOURS.join(", ")} (got #{key.inspect})"
      end

      contour
    end
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
    notes.length >= 3 && first_note.pitch < highest_pitch && last_note.pitch < highest_pitch
  end

  def valley?
    notes.length >= 3 && first_note.pitch > lowest_pitch && last_note.pitch > lowest_pitch
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
    highest_pitch > lowest_pitch &&
      ((first_note.pitch == lowest_pitch && last_note.pitch == highest_pitch) ||
        (first_note.pitch == highest_pitch && last_note.pitch == lowest_pitch))
  end

  def pitch_numbers
    @pitch_numbers ||= notes.map { |note| note.pitch.midi_note_number }
  end

  # Zigzag walk: a trend reversal is confirmed only when the melody retraces at
  # least TREND_REVERSAL_SEMITONES from the running extreme of the current trend,
  # so stepwise neighbor-note undulation never registers as a trend change.
  def trend_directions
    @trend_directions ||= begin
      directions = []
      direction = nil
      high = low = pitch_numbers.first
      extreme = nil
      pitch_numbers.drop(1).each do |number|
        case direction
        when nil # no trend confirmed yet
          if number - low >= TREND_REVERSAL_SEMITONES
            direction = :ascending
            extreme = number
            directions << direction
          elsif high - number >= TREND_REVERSAL_SEMITONES
            direction = :descending
            extreme = number
            directions << direction
          else
            high = [high, number].max
            low = [low, number].min
          end
        when :ascending
          if number > extreme
            extreme = number
          elsif extreme - number >= TREND_REVERSAL_SEMITONES
            direction = :descending
            extreme = number
            directions << direction
          end
        when :descending
          if number < extreme
            extreme = number
          elsif number - extreme >= TREND_REVERSAL_SEMITONES
            direction = :ascending
            extreme = number
            directions << direction
          end
        end
      end
      directions
    end
  end
end
