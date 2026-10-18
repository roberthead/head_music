# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline < HeadMusic::Style::Guidelines::NoParallelPerfect
  private

  # Each weak-beat interval with the downbeat interval after it.
  def interval_pairs
    weak_beat_harmonic_intervals.filter_map do |weak_interval|
      next_downbeat = next_downbeat_interval(weak_interval)
      [weak_interval, next_downbeat] if next_downbeat
    end
  end

  def weak_beat_harmonic_intervals
    weak_beat_positions.filter_map { |position| interval_with_cantus(position) }
  end

  def weak_beat_positions
    notes.map(&:position).reject { |pos| downbeat_position?(pos) }
  end

  def next_downbeat_interval(weak_interval)
    next_cf_note = cantus_firmus.notes.detect { |n| n.position > weak_interval.position }
    interval_with_cantus(next_cf_note.position) if next_cf_note
  end
end
