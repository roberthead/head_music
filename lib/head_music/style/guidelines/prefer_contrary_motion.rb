# frozen_string_literal: true

# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::PreferContraryMotion < HeadMusic::Style::Annotation
  MESSAGE = 'Prefer contrary motion. Move voices in different melodic directions.'

  def marks
    return nil if notes.length < 2
    return nil if direct_motion_ratio <= 0.5

    direct_motions.map { |motion| HeadMusic::Style::Mark.for_all(motion.notes) }
  end

  private

  def direct_motions
    motions.select(&:direct?)
  end

  def direct_motion_ratio
    return 0 if motions.empty?

    direct_motions.count / motions.count.to_f
  end
end
