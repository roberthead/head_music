# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody without the configured contour
# Configure the threshold with the factory, e.g. Contoured.with(:arch).
class HeadMusic::Style::Guidelines::Contoured < HeadMusic::Style::Annotation
  CONTOURS = %i[ascending descending arch valley wave static].freeze

  def self.with(contour_key)
    super(contour: contour_key.to_s.underscore.to_sym)
  end

  def marks
    # mark all notes if the melody does not match the configured contour
    return if matches_contour?

    HeadMusic::Style::Mark.for_all(notes)
  end

  def message
    "Write a melody with the #{contour} contour."
  end

  private

  def contour
    options.fetch(:contour)
  end

  def matches_contour?
    send("#{contour}?")
  end

  def ascending?
    # to be implemented
  end

  def descending?
    # to be implemented
  end

  def arch?
    # to be implemented
  end

  def valley?
    # to be implemented
  end

  def wave?
    # to be implemented
  end

  def static?
    # to be implemented
  end
end
