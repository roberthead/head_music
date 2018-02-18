# frozen_string_literal: true

class HeadMusic::Circle
  def self.of_fifths
    get(7)
  end

  def self.of_fourths
    get(5)
  end

  def self.get(interval = 7)
    @circles ||= {}
    @circles[interval.to_i] ||= new(interval)
  end

  attr_reader :interval, :pitch_classes

  def initialize(interval)
    @interval = HeadMusic::Interval.get(interval.to_i)
    @pitch_classes = pitch_classes_by_interval(interval)
  end

  def index(pitch_class)
    @pitch_classes.index(HeadMusic::Spelling.get(pitch_class).pitch_class)
  end

  private_class_method :new

  private

  def pitch_classes_by_interval(interval)
    [HeadMusic::PitchClass.get(0)].tap do |list|
      loop do
        next_pitch_class = list.last + interval
        break if next_pitch_class == list.first
        list << next_pitch_class
      end
    end
  end
end
