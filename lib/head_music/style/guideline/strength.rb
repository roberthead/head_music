module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # How much a guideline weighs against its siblings in the same tier: a
  # prohibition weighs twice a preference. Extended rather than included, for
  # the reason Wording gives -- the severity belongs to the rule, not to one
  # analysis.
  #
  # Orthogonal to tier. Tier is the list a guide declares an item in and cannot
  # be a property of the item, because ContourMelody treats as background
  # exactly what DiatonicMelody teaches. Strength has no such conflict:
  # PreferContraryMotion is a preference in every guide that declares it. It is
  # therefore declared on the class and overridable per item for the
  # tradition-dependent case.
  module Strength
    UNITS = {strong: 2, weak: 1}.freeze

    VALUES = UNITS.keys.freeze

    DEFAULT = :strong

    # Validated in one place and called from both the macro and
    # GuideItem#initialize -- belt and braces, as Contoured already does for
    # its contour, so a value reaching the second seam without the first still
    # raises rather than multiplying by nil.
    def self.normalized(value, source)
      normalized = value.to_s.downcase.to_sym
      return normalized if VALUES.include?(normalized)

      raise ArgumentError, "#{source} strength must be one of: #{VALUES.join(", ")} (got #{value.inspect})"
    end

    def self.units(value)
      UNITS.fetch(value)
    end

    # Required for :weak and rejected for :strong, so "every weak declaration
    # carries a reason" is true by construction rather than asserted by a spec.
    #
    # Never inherited: WeakBeatDissonanceTreatment bases the third-species and
    # triple-meter treatments, which are the taught rule of their own guides,
    # and MinimumThreshold bases both a gate and a rubric item. An inheriting
    # macro would let one careless declaration on a shared analysis base demote
    # several taught rules silently. This matches the choice Guides::Base makes
    # for declarations.
    def strength(value = nil, because: nil)
      return declared_strength if value.nil?

      normalized = HeadMusic::Style::Guideline::Strength.normalized(value, name)
      validate_reason!(normalized, because)
      @declared_strength = normalized
    end

    # Not memoized: a lazy write to a class ivar during grading would reopen
    # the race that Guide::ALL.each(&:guide_items) exists to close.
    def declared_strength
      defined?(@declared_strength) ? @declared_strength : HeadMusic::Style::Guideline::Strength::DEFAULT
    end

    private

    def validate_reason!(normalized, because)
      if normalized == :weak && because.to_s.strip.empty?
        raise ArgumentError, "#{name} declares strength :weak and must say why with because:"
      end
      return unless normalized == :strong && because

      raise ArgumentError, "#{name} declares strength :strong, which is the default and takes no because:"
    end
  end
end
