# Parses ABC notation into HeadMusic::Content compositions
module HeadMusic::Notation::ABC
  # Converts the tune's unit note length and a per-note multiplier string
  # (e.g. "2", "3/2", "/", "//") into a HeadMusic::Rudiment::RhythmicValue.
  class DurationResolver
    # Longest supported duration: a maxima (8 whole notes).
    MAX_FRACTION = Rational(8)

    # A reduced binary fraction's odd factor determines the dot count:
    # 1 -> plain, 3 -> dotted, 7 -> double-dotted, 15 -> triple-dotted.
    DOTS_BY_ODD_FACTOR = {1 => 0, 3 => 1, 7 => 2, 15 => 3}.freeze

    UNIT_NAMES_BY_MULTIPLE = {1 => "whole", 2 => "double whole", 4 => "longa", 8 => "maxima"}.freeze

    MULTIPLIER_PATTERN = %r{\A(\d+)?(?:(/+)(\d+)?)?\z}

    attr_reader :unit_note_length

    def initialize(unit_note_length)
      @unit_note_length = Rational(unit_note_length)
    end

    # scale: an extra multiplier applied outside the note's own length
    # string, used for broken-rhythm pairs (3/2 and 1/2).
    def rhythmic_value(multiplier_string, scale: Rational(1))
      fraction = unit_note_length * multiplier(multiplier_string) * scale
      validate_fraction!(fraction, multiplier_string)
      build_rhythmic_value(fraction, multiplier_string)
    end

    private

    def multiplier(multiplier_string)
      source = multiplier_string.to_s
      match = MULTIPLIER_PATTERN.match(source)
      raise_error("malformed note length multiplier", source) unless match

      numerator = (match[1] || 1).to_i
      slashes = match[2]
      denominator = match[3]
      return Rational(numerator) unless slashes
      return Rational(numerator, 2**slashes.length) unless denominator

      # An explicit denominator pairs with exactly one slash ("3/2", not "3//2").
      raise_error("malformed note length multiplier", source) if slashes.length > 1
      raise_error("note length denominator cannot be zero", source) if denominator.to_i.zero?
      Rational(numerator, denominator.to_i)
    end

    def validate_fraction!(fraction, source)
      raise_error("note length must be positive", source) if fraction <= 0
      raise_error("note length exceeds #{MAX_FRACTION.to_i} whole notes", source) if fraction > MAX_FRACTION
      return if power_of_two?(fraction.denominator)

      raise_error("note length #{fraction} is not expressible in binary note values", source)
    end

    # Fractions whose odd factor is one less than a power of two map onto a
    # single (possibly dotted) note; anything else becomes a chain of tied notes,
    # peeling off the largest dotted-expressible head each pass.
    def build_rhythmic_value(fraction, source)
      dots = DOTS_BY_ODD_FACTOR[odd_factor(fraction.numerator)]
      return single_value(fraction, dots, source) if dots

      head = greedy_head(fraction)
      tail = build_rhythmic_value(fraction - head, source)
      single_value(head, DOTS_BY_ODD_FACTOR.fetch(odd_factor(head.numerator)), source, tied_value: tail)
    end

    def single_value(fraction, dots, source, tied_value: nil)
      # A value with d dots spans (2^(d+1) - 1) / 2^d of its unit.
      unit_fraction = fraction * Rational(2**dots, (2**(dots + 1)) - 1)
      HeadMusic::Rudiment::RhythmicValue.new(unit_for(unit_fraction, source), dots: dots, tied_value: tied_value)
    end

    # The largest leading run of set bits (capped at four, i.e. triple-dotted)
    # forms a dotted-expressible head for the tied-value decomposition.
    def greedy_head(fraction)
      numerator = fraction.numerator
      bits = numerator.bit_length
      run = 0
      run += 1 while run < 4 && run < bits && numerator[bits - 1 - run] == 1
      Rational(((1 << run) - 1) << (bits - run), fraction.denominator)
    end

    def unit_for(unit_fraction, source)
      unit = if unit_fraction >= 1
        name = UNIT_NAMES_BY_MULTIPLE[unit_fraction.numerator]
        name && HeadMusic::Rudiment::RhythmicUnit.get(name)
      else
        HeadMusic::Rudiment::RhythmicUnit.for_denominator_value(unit_fraction.denominator)
      end
      raise_error("no rhythmic unit for a note length of #{unit_fraction}", source) unless unit
      unit
    end

    def odd_factor(integer)
      integer >>= 1 while integer.even?
      integer
    end

    def power_of_two?(integer)
      (integer & (integer - 1)).zero?
    end

    def raise_error(message, source)
      raise HeadMusic::Notation::ABC::ParseError.new(message, snippet: source)
    end
  end
end
