# Helpers for exercising a guideline through the assess seam.
module StyleAssessmentHelper
  # Builds the guide item a guide would declare and assesses a voice against
  # it. Constructs the item directly rather than through .with, so the three
  # guidelines that take a positional first argument configure the same way
  # here as every other.
  # The sentence a guideline carries, without needing a voice that breaks it.
  # An assessment reports nothing when adherent, so this is what to ask when
  # the subject of the example is the wording rather than the finding.
  def violation_text(guideline, **config)
    HeadMusic::Style::GuideItem.new(guideline, config).violation_preview
  end

  def assess(guideline, voice, tier: :primary, **config)
    HeadMusic::Style::GuideItem.new(guideline, config).assess(voice, tier)
  end
end

RSpec.configure { |config| config.include StyleAssessmentHelper }

# Mark conveniences, on the assessment rather than the analyzer: the analyzer
# does not escape Guideline.assess, so a spec holds one of these instead.
class HeadMusic::Style::GuideItemAssessment
  def marks_count
    marks.length
  end

  def first_mark
    marks.first
  end

  def first_mark_code
    first_mark&.code
  end

  def marks_array
    marks
  end
end
