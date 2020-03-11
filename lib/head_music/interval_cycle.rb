# frozen_string_literal: true

# An Interval Cycle is a collection of pitch classes created from a sequence of the same interval class.
class HeadMusic::IntervalCycle
  def self.get(interval = 7)
    @circles ||= {}
    interval = interval.to_s.gsub(/^C/i, '').to_i
    @circles[interval.to_i] ||= new(interval)
  end

  attr_reader :interval, :pitch_classes

  def initialize(interval)
    @interval = interval.to_i
    @pitch_classes = pitch_classes_by_interval
  end

  def index(pitch_class)
    @pitch_classes.index(HeadMusic::Spelling.get(pitch_class).pitch_class)
  end

  private_class_method :new

  private

  def pitch_classes_by_interval
    [HeadMusic::PitchClass.get(0)].tap do |list|
      loop do
        next_pitch_class = list.last + interval
        break if next_pitch_class == list.first

        list << next_pitch_class
      end
    end
  end
end
