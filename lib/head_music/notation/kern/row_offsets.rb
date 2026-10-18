# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # Where a bar's data rows fall: one at each attack, and between two
  # attacks, or the last and the bar's end, the fewest evenly spaced null
  # rows that land on every dynamic between them.
  #
  # A row has a time of its own only where something attacks. Rows between
  # two such rows split the time between them evenly, so a dynamic where
  # nothing attacks goes on one of a run of null rows spaced to land on it.
  module RowOffsets
    def self.for(attacks, dynamics, length)
      untimed = (attacks + [length]).each_cons(2).flat_map { |from, to| untimed(from, to, dynamics) }
      (attacks + untimed).sort
    end

    def self.untimed(from, to, dynamics)
      inside = dynamics.select { |offset| offset > from && offset < to }
      return [] if inside.empty?

      step = inside.map { |offset| offset - from }.reduce(to - from) { |gcd, span| rational_gcd(gcd, span) }
      (1...((to - from) / step)).map { |index| from + step * index }
    end
    private_class_method :untimed

    def self.rational_gcd(one, other)
      Rational(one.numerator.gcd(other.numerator), one.denominator.lcm(other.denominator))
    end
    private_class_method :rational_gcd
  end
end
