module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # What sounds together: the intervals between this voice and the cantus
  # firmus, and the motion from one to the next.
  module HarmonicContext
    protected

    def motions
      downbeat_harmonic_intervals.each_cons(2).map do |harmonic_interval_pair|
        HeadMusic::Analysis::Motion.new(*harmonic_interval_pair)
      end
    end

    def downbeat_harmonic_intervals
      @downbeat_harmonic_intervals ||=
        sounding_together(
          cantus_firmus.notes.map { |note| HeadMusic::Analysis::HarmonicInterval.new(note.voice, voice, note.position) }
        )
    end

    def harmonic_intervals
      @harmonic_intervals ||=
        sounding_together(
          positions.map { |position| HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, position) }
        )
    end

    # Fewer than two notes means one voice is silent, so nothing sounds together.
    def sounding_together(intervals)
      intervals.reject { |interval| interval.notes.length < 2 }
    end

    # Every moment any voice attacks, so an interval is measured wherever one
    # could have been heard.
    def positions
      @positions ||= voices.flat_map(&:notes).map(&:position).sort.uniq(&:to_s)
    end
  end
end
