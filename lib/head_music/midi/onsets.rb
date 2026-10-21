module HeadMusic::MIDI
  # The times notes start, sorted and unique.
  class Onsets
    def initialize(times)
      @times = times.uniq.sort
    end

    # Whether a note starts before +to+ and after +from+, or at it with
    # +including_from+.
    def between?(from, to, including_from: false)
      onset = @times.bsearch { |time| including_from ? time >= from : time > from }
      !onset.nil? && onset < to
    end
  end
end
