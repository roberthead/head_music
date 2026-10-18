module HeadMusic
  module Notation
    # The exact written length of a (possibly dotted) rhythmic value as a
    # fraction of a whole note, and the inverse: the rhythmic value a fraction
    # of a whole note denotes. Exact fractions keep downstream arithmetic (ABC
    # multipliers, MusicXML divisions, LilyPond bar sums) exact.
    #
    # A tuplet value has two lengths. Its written one, which leaves out the
    # ratio, names the note a score shows: ABC lengths, LilyPond tokens, and
    # MusicXML <type>. Its sounding one, which takes the ratio in, is the time
    # it fills: kern reciprocals, MusicXML <duration>, and bar sums.
    module DottedDuration
      # Longest supported duration: a maxima (8 whole notes).
      MAX_FRACTION = Rational(8)

      # A reduced binary fraction's odd factor determines the dot count:
      # 1 -> plain, 3 -> dotted, 7 -> double-dotted, 15 -> triple-dotted.
      DOTS_BY_ODD_FACTOR = {1 => 0, 3 => 1, 7 => 2, 15 => 3}.freeze

      UNIT_NAMES_BY_MULTIPLE = {1 => "whole", 2 => "double whole", 4 => "longa", 8 => "maxima"}.freeze

      module_function

      def dotted_unit_fraction(rhythmic_value)
        rhythmic_value.written_fraction
      end

      # One link's length under its tuplet ratio.
      def sounding_fraction(link)
        link.link_fraction
      end

      # The rhythmic value spanning a fraction of a whole note, or nil when no
      # binary note value (or tied chain of them) can express it. Under a
      # tuplet ratio, the fraction is the sounding length, and every link of
      # the answer carries the ratio.
      def rhythmic_value_for(fraction, tuplet: nil)
        ratio = tuplet && HeadMusic::Rudiment::TupletRatio.get(tuplet)
        written = ratio ? Rational(fraction) / ratio.factor : Rational(fraction)
        return unless expressible?(written)

        value = build_rhythmic_value(written)
        ratio ? value&.with_tuplet(ratio) : value
      end

      # One value tying the given values together in order.
      def tied(values)
        values.reverse.reduce { |tail, head| head.append_tied(tail) }
      end

      # The ratio a non-binary undotted value sounds under, or nil. When the
      # denominator has an odd factor m, m notes take the time of the largest
      # odd part of the numerator times a power of two below m: 1/12 is a 3:2
      # eighth, 1/20 a 5:4 sixteenth, 3/10 a 5:3 half.
      def tuplet_ratio(fraction)
        fraction = Rational(fraction)
        actual = odd_factor(fraction.denominator)
        return if actual == 1

        normal = odd_factor(fraction.numerator)
        normal = 1 if normal > actual
        normal *= 2 while normal * 2 < actual
        HeadMusic::Rudiment::TupletRatio.get([actual, normal])
      end

      # A rest filling a stretch, under the ratio its length implies when no
      # plain value spans it, as after a voice's last triplet.
      def rest_value(fraction)
        rhythmic_value_for(fraction) || rhythmic_value_for(fraction, tuplet: tuplet_ratio(fraction))
      end

      def expressible?(fraction)
        fraction.positive? && fraction <= MAX_FRACTION && power_of_two?(fraction.denominator)
      end

      # Fractions whose odd factor is one less than a power of two map onto a
      # single (possibly dotted) note; anything else becomes a chain of tied notes,
      # peeling off the largest dotted-expressible head each pass.
      def build_rhythmic_value(fraction)
        dots = DOTS_BY_ODD_FACTOR[odd_factor(fraction.numerator)]
        return single_value(fraction, dots) if dots

        head = greedy_head(fraction)
        tail = build_rhythmic_value(fraction - head)
        return unless tail

        single_value(head, DOTS_BY_ODD_FACTOR.fetch(odd_factor(head.numerator)), tied_value: tail)
      end

      def single_value(fraction, dots, tied_value: nil)
        # A value with d dots spans (2^(d+1) - 1) / 2^d of its unit.
        unit = unit_for(fraction * Rational(2**dots, (2**(dots + 1)) - 1))
        return unless unit

        HeadMusic::Rudiment::RhythmicValue.new(unit, dots: dots, tied_value: tied_value)
      end

      # The largest leading run of set bits (capped at four, i.e. triple-dotted)
      # forms a dotted-expressible head for the tied-value decomposition.
      def greedy_head(fraction)
        numerator = fraction.numerator
        bits = numerator.bit_length
        run = leading_set_bits(numerator, bits)
        Rational(((1 << run) - 1) << (bits - run), fraction.denominator)
      end

      # Length of the leading run of set bits, capped at four (triple-dotted).
      def leading_set_bits(numerator, bits)
        run = 0
        run += 1 while run < 4 && run < bits && numerator[bits - 1 - run] == 1
        run
      end

      def unit_for(unit_fraction)
        if unit_fraction >= 1
          name = UNIT_NAMES_BY_MULTIPLE[unit_fraction.numerator]
          name && HeadMusic::Rudiment::RhythmicUnit.get(name)
        else
          HeadMusic::Rudiment::RhythmicUnit.for_denominator_value(unit_fraction.denominator)
        end
      end

      def odd_factor(integer)
        integer >>= 1 while integer.even?
        integer
      end

      def power_of_two?(integer)
        (integer & (integer - 1)).zero?
      end
    end
  end
end
