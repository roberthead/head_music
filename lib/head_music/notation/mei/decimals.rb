module HeadMusic::Notation::MEI
  # Numbers as MEI's decimals: exact where the decimal ends, otherwise to four
  # places.
  module Decimals
    PLACES = 4

    module_function

    def format(value)
      value = Rational(value)
      value = value.round(PLACES) unless terminating?(value.denominator)
      return value.numerator.to_s if value.denominator == 1

      places = decimal_places(value.denominator)
      digits = (value.abs * 10**places).to_i.to_s.rjust(places + 1, "0")
      sign = value.negative? ? "-" : ""
      "#{sign}#{digits[0...-places]}.#{digits[-places..]}"
    end

    def terminating?(denominator)
      [2, 5].each { |factor| denominator /= factor while (denominator % factor).zero? }
      denominator == 1
    end

    def decimal_places(denominator)
      (0..).find { |places| (10**places % denominator).zero? }
    end
  end
end
