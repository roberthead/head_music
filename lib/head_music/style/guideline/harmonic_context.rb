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
      @downbeat_harmonic_intervals ||= cantus_firmus.notes.filter_map { |note| interval_with_cantus(note.position) }
    end

    def harmonic_intervals
      @harmonic_intervals ||= positions.filter_map { |position| interval_with_cantus(position) }
    end

    # Nil where the voice or the cantus firmus is silent, so nothing sounds
    # together.
    def interval_with_cantus(position)
      interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, position)
      interval if interval.notes.length == 2
    end

    def dissonant_with_cantus_at?(position)
      interval_with_cantus(position)&.dissonance?(:two_part_harmony) || false
    end

    def consonant_with_cantus_at?(position)
      interval_with_cantus(position)&.consonance?(:two_part_harmony) || false
    end

    # Every moment any voice attacks, so an interval is measured wherever one
    # could have been heard.
    def positions
      @positions ||= voices.flat_map(&:notes).map(&:position).sort.uniq(&:to_s)
    end
  end
end
