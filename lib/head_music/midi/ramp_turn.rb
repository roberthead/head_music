module HeadMusic::MIDI
  # The tempo where a ramp turns into one the other way, which export writes
  # no step at. A step holds the logarithmic mean of the tempos at its
  # count's ends, so the tempo at the end of the last count is the one that,
  # with the ramp's change a count, gives the last two steps those means.
  module RampTurn
    ITERATIONS = 8

    # +last+ and +before+ are the last two steps, in quarters a minute.
    def self.per_minute(last, before)
      last, before = last.to_f, before.to_f
      change = before - last
      tempo = last - change / 2
      ITERATIONS.times do
        error = last - logarithmic_mean(tempo + change, tempo)
        change += before - logarithmic_mean(tempo + 2 * change, tempo + change) - error
        tempo += error
      end
      tempo
    end

    def self.logarithmic_mean(a, b)
      (a == b) ? a : (a - b) / Math.log(a / b)
    end
  end
end
