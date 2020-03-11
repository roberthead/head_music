# frozen_string_literal: true

require 'head_music/interval_cycle'

# A Circle of Fifths or Fourths shows relationships between pitch classes
class HeadMusic::Circle < HeadMusic::IntervalCycle
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

  # Accepts an interval (as an integer number of semitones)
  def initialize(interval)
    @interval = interval.to_i
    @pitch_classes = pitch_classes_by_interval
  end

  def index(pitch_class)
    @pitch_classes.index(HeadMusic::Spelling.get(pitch_class).pitch_class)
  end

  private_class_method :new

  private

  def interval_cycle
    @interval_cycle ||= HeadMusic::IntervalCycle.get(interval)
  end

  def pitch_classes_by_interval
    interval_cycle.send(:pitch_classes_by_interval)
  end
end
