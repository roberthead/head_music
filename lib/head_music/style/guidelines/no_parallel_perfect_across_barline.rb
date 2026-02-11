# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline < HeadMusic::Style::Annotation
  MESSAGE = "Avoid parallel perfect consonances from weak beat to the following downbeat."

  def marks
    parallel_perfect_across_barline_pairs.map do |pair|
      HeadMusic::Style::Mark.for_all(pair.flat_map(&:notes))
    end
  end

  private

  def parallel_perfect_across_barline_pairs
    weak_strong_interval_pairs.select do |weak, strong|
      weak.perfect_consonance?(:two_part_harmony) &&
        strong.perfect_consonance?(:two_part_harmony) &&
        same_simple_type?(weak, strong)
    end
  end

  def weak_strong_interval_pairs
    weak_beat_harmonic_intervals.filter_map do |weak_interval|
      next_downbeat = next_downbeat_interval(weak_interval)
      [weak_interval, next_downbeat] if next_downbeat
    end
  end

  def weak_beat_harmonic_intervals
    weak_beat_positions.filter_map do |position|
      interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, position)
      interval if interval.notes.length == 2
    end
  end

  def weak_beat_positions
    notes.map(&:position).reject { |pos| downbeat_position?(pos) }
  end

  def downbeat_position?(position)
    cantus_firmus_positions.include?(position.to_s)
  end

  def cantus_firmus_positions
    @cantus_firmus_positions ||= Set.new(cantus_firmus.notes.map { |n| n.position.to_s })
  end

  def next_downbeat_interval(weak_interval)
    next_cf_note = cantus_firmus.notes.detect { |n| n.position > weak_interval.position }
    return unless next_cf_note

    interval = HeadMusic::Analysis::HarmonicInterval.new(cantus_firmus, voice, next_cf_note.position)
    interval if interval.notes.length == 2
  end

  def same_simple_type?(first, second)
    first.simple_number == second.simple_number
  end
end
