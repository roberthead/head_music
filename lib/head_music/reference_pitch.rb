# frozen_string_literal: true

# A reference pitch has a pitch and a frequency
# With no arguments, it assumes that A4 = 440.0 Hz
class HeadMusic::ReferencePitch
  DEFAULT_PITCH_NAME = 'A4'
  DEFAULT_FREQUENCY = 440.0

  attr_reader :pitch, :frequency

  def initialize(pitch: nil, frequency: nil)
    @pitch = HeadMusic::Pitch.get(pitch || DEFAULT_PITCH_NAME)
    @frequency = frequency || DEFAULT_FREQUENCY
  end

  # Also known as the modern pitch standard, concert pitch, Stuttgart pitch, Scheibler pitch, and ISO 16
  def self.a440
    @a440 ||= new(frequency: 440.0)
  end

  # The pitch standard established by French law in 1859. Also called continental pitch and international pitch.
  def self.french
    @french ||= new(frequency: 435.0)
  end

  # British standard in mid-19th century. Also called high pitch.
  def self.old_philharmonic
    @old_philharmonic ||= new(frequency: 452.4)
  end

  # British standard in 1896. Also called low pitch.
  def self.new_philharmonic
    @new_philharmonic ||= new(frequency: 439.0)
  end

  # Also called philosophic pitch
  def self.scientific
    @scientific ||= new(pitch: 'C4', frequency: 256.0)
  end

  # the Schiller Institute's recommended tuning for A of 432 Hz[7][8] is for the Pythagorean ratio of 27:16, rather than the logarithmic ratio of equal temperament tuning.
  def self.schiller
    @schiller ||= new(frequency: 432.0)
  end

  # used by modern period instrument groups
  def self.modern_baroque
    @modern_baroque ||= new(frequency: 415.0)
  end

  def self.modern_new_york_philharmonic
    @new_york_philharmonic ||= new(frequency: 442.0)
  end

  def self.modern_european_symphonic
    @european_symphonic ||= new(frequency: 443.0)
  end
end
