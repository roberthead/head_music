# frozen_string_literal: true

# A melodic interval is the distance between one note and the next.
class HeadMusic::MelodicInterval
  attr_reader :first_note, :second_note

  def initialize(note1, note2)
    @first_note = note1
    @second_note = note2
  end

  def diatonic_interval
    @diatonic_interval ||= HeadMusic::DiatonicInterval.new(first_pitch, second_pitch)
  end

  def position_start
    first_note.position
  end

  def position_end
    second_note.next_position
  end

  def notes
    [first_note, second_note]
  end

  def pitches
    [first_pitch, second_pitch]
  end

  def first_pitch
    @first_pitch ||= first_note.pitch
  end

  def second_pitch
    @second_pitch ||= second_note.pitch
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

  def spans?(pitch)
    pitch >= low_pitch && pitch <= high_pitch
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

    HeadMusic::PitchSet.new(combined_pitches).consonant_triad?
  end

  def method_missing(method_name, *args, &block)
    respond_to_missing?(method_name) ? diatonic_interval.send(method_name, *args, &block) : super
  end

  def respond_to_missing?(method_name, *_args)
    diatonic_interval.respond_to?(method_name)
  end
end
