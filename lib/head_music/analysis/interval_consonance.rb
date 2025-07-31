# Analysis class that combines an interval with a style tradition to determine consonance
class HeadMusic::Analysis::IntervalConsonance
  attr_reader :interval, :style_tradition

  def initialize(interval, style_tradition = HeadMusic::Style::ModernTradition.new)
    @interval = interval
    @style_tradition = style_tradition.is_a?(HeadMusic::Style::Tradition) ?
                       style_tradition :
                       HeadMusic::Style::Tradition.get(style_tradition)
  end

  def classification
    @classification ||= style_tradition.consonance_classification(interval)
  end

  def consonance
    @consonance ||= HeadMusic::Rudiment::Consonance.get(classification)
  end

  def consonant?
    [HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE, HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE].include?(classification)
  end

  def dissonant?
    [HeadMusic::Rudiment::Consonance::MILD_DISSONANCE, HeadMusic::Rudiment::Consonance::HARSH_DISSONANCE, HeadMusic::Rudiment::Consonance::DISSONANCE].include?(classification)
  end

  def contextual?
    classification == HeadMusic::Rudiment::Consonance::CONTEXTUAL
  end

  def perfect_consonance?
    classification == HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE
  end

  def imperfect_consonance?
    classification == HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE
  end

  def mild_dissonance?
    classification == HeadMusic::Rudiment::Consonance::MILD_DISSONANCE
  end

  def harsh_dissonance?
    classification == HeadMusic::Rudiment::Consonance::HARSH_DISSONANCE
  end

  def dissonance?
    classification == HeadMusic::Rudiment::Consonance::DISSONANCE
  end
end
