# frozen_string_literal: true

# An Interval Cycle is a collection of pitch classes created from a sequence of the same interval class.
class HeadMusic::IntervalCycle
  attr_reader :interval, :starting_pitch

  def self.get(interval = 7)
    @interval_cycles ||= {}
    interval = interval.to_s.gsub(/^C/i, '').to_i
    interval = HeadMusic::ChromaticInterval.get(interval)
    @interval_cycles[interval.to_i] ||= new(interval: interval, starting_pitch: 'C4')
  end

  def initialize(interval:, starting_pitch: 'C4')
    @interval = interval if interval.is_a?(HeadMusic::DiatonicInterval)
    @interval ||= interval if interval.is_a?(HeadMusic::ChromaticInterval)
    @interval ||= HeadMusic::ChromaticInterval.get(interval) if interval.to_s.match?(/\d/)
    @interval ||= HeadMusic::DiatonicInterval.get(interval)
    @starting_pitch = HeadMusic::Pitch.get(starting_pitch)
  end

  def pitches
    @pitches ||= pitches_up
  end

  def pitch_classes
    @pitch_classes ||= pitches.map(&:pitch_class)
  end

  def pitch_class_set
    @pitch_class_set ||= HeadMusic::PitchClassSet.new(pitches)
  end

  def spellings
    @spellings ||= pitches.map(&:spelling)
  end

  protected

  def pitches_up
    @pitches_up ||= begin
      [starting_pitch].tap do |list|
        loop do
          next_pitch = list.last + interval
          next_pitch -= octave while next_pitch - starting_pitch > 12
          break if next_pitch.pitch_class == list.first.pitch_class

          list << next_pitch
        end
      end
    end
  end

  def octave
    @octave ||= HeadMusic::DiatonicInterval.get(:perfect_octave)
  end
end
