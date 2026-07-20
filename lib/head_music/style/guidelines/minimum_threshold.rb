# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Base class for guidelines that flag a voice for falling short of a minimum
# count. Subclasses supply the actual count being measured against the minimum.
class HeadMusic::Style::Guidelines::MinimumThreshold < HeadMusic::Style::Annotation
  def self.with(minimum, **options)
    super(minimum: minimum, **options)
  end

  def self.default_gate?
    true
  end

  private

  def minimum
    options.fetch(:minimum)
  end

  def actual_count
    raise NotImplementedError
  end

  def no_placements_mark
    HeadMusic::Style::Mark.new(
      HeadMusic::Content::Position.new(composition, "1:1"),
      HeadMusic::Content::Position.new(composition, "2:1"),
      fitness: 0
    )
  end

  def deficiency_mark
    return unless actual_count < minimum

    HeadMusic::Style::Mark.for_all(placements, fitness: actual_count.to_f / minimum)
  end
end
