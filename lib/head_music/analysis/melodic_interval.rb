# A module for musical analysis
module HeadMusic::Analysis; end

# A melodic interval is the distance between two sequential pitches.
class HeadMusic::Analysis::MelodicInterval
  attr_reader :first_pitch, :second_pitch

  def initialize(first, second)
    @first_pitch, @second_pitch = extract_pitches(first, second)
  end

  def diatonic_interval
    @diatonic_interval ||= HeadMusic::Analysis::DiatonicInterval.new(first_pitch, second_pitch)
  end

  def pitches
    [first_pitch, second_pitch]
  end

  def to_s
    [direction, diatonic_interval].join(" ")
  end

  def ascending?
    direction == :ascending
  end

  def descending?
    direction == :descending
  end

  def moving?
    ascending? || descending?
  end

  def repetition?
    !moving?
  end

  def high_pitch
    pitches.max
  end

  def low_pitch
    pitches.min
  end

  def direction
    @direction ||=
      if first_pitch < second_pitch
        :ascending
      elsif first_pitch > second_pitch
        :descending
      else
        :none
      end
  end

  def spells_consonant_triad_with?(other_interval)
    return false if step? || other_interval.step?

    combined_pitches = (pitches + other_interval.pitches).uniq
    return false if combined_pitches.length < 3

    HeadMusic::Analysis::PitchCollection.new(combined_pitches).consonant_triad?
  end

  def method_missing(method_name, *args, &block)
    diatonic_interval.respond_to?(method_name) ? diatonic_interval.send(method_name, *args, &block) : super
  end

  def respond_to_missing?(method_name, include_private = false)
    diatonic_interval.respond_to?(method_name, include_private) || super
  end

  private

  def extract_pitches(first, second)
    first_pitch = first.respond_to?(:pitch) ? first.pitch : first
    second_pitch = second.respond_to?(:pitch) ? second.pitch : second
    [first_pitch, second_pitch]
  end
end
