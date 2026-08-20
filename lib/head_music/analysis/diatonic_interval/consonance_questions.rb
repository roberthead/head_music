class HeadMusic::Analysis::DiatonicInterval
  # Everything an interval can be asked about how it sounds together. Each
  # question is put to an IntervalConsonance built for the style in hand, since
  # the same interval is consonant in one tradition and not in another -- the
  # fourth above all. The style travels with the question rather than with the
  # interval, so every one of these takes it and none of them remember it.
  module ConsonanceQuestions
    STANDARD_PRACTICE = :standard_practice

    def consonance_analysis(style = STANDARD_PRACTICE)
      HeadMusic::Analysis::IntervalConsonance.new(self, style)
    end

    def consonance(style = STANDARD_PRACTICE)
      consonance_analysis(style).consonance
    end

    def consonance_classification(style: STANDARD_PRACTICE)
      consonance_analysis(style).classification
    end

    def consonant?(style = STANDARD_PRACTICE)
      consonance_analysis(style).consonant?
    end

    def dissonant?(style = STANDARD_PRACTICE)
      consonance_analysis(style).dissonant?
    end

    # Both spellings of each question have been published, and both ask the
    # same thing.
    alias_method :consonance?, :consonant?
    alias_method :dissonance?, :dissonant?

    def perfect_consonance?(style = STANDARD_PRACTICE)
      consonance_analysis(style).perfect_consonance?
    end

    def imperfect_consonance?(style = STANDARD_PRACTICE)
      consonance_analysis(style).imperfect_consonance?
    end
  end
end
