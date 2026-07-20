module HeadMusic
  module Notation
    # The exact fractional length of a (possibly dotted) rhythmic value in
    # terms of its own unit. RhythmicValue's own value methods return Floats,
    # so the fraction is rebuilt here from the unit's integer numerator and
    # denominator to keep downstream arithmetic (ABC multipliers, MusicXML
    # divisions) exact.
    module DottedDuration
      module_function

      def dotted_unit_fraction(rhythmic_value)
        unit = rhythmic_value.unit
        dots = rhythmic_value.dots
        # A value with d dots spans (2^(d+1) - 1) / 2^d of its own unit.
        Rational(unit.numerator, unit.denominator) * Rational((2**(dots + 1)) - 1, 2**dots)
      end
    end
  end
end
