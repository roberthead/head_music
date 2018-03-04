# frozen_string_literal: true

# A placement is a note or rest at a position within a voice in a composition
class HeadMusic::Placement
  include Comparable

  attr_reader :voice, :position, :rhythmic_value, :pitch
  delegate :composition, to: :voice
  delegate :spelling, to: :pitch, allow_nil: true

  def initialize(voice, position, rhythmic_value, pitch = nil)
    ensure_attributes(voice, position, rhythmic_value, pitch)
  end

  def note?
    pitch
  end

  def rest?
    !note?
  end

  def next_position
    @next_position ||= position + rhythmic_value
  end

  def <=>(other)
    position <=> other.position
  end

  def during?(other_placement)
    starts_during?(other_placement) || ends_during?(other_placement) || wraps?(other_placement)
  end

  def to_s
    "#{rhythmic_value} #{pitch ? pitch : 'rest'} at #{position}"
  end

  private

  def starts_during?(other_placement)
    position >= other_placement.position && position < other_placement.next_position
  end

  def ends_during?(other_placement)
    next_position > other_placement.position && next_position <= other_placement.next_position
  end

  def wraps?(other_placement)
    position <= other_placement.position && next_position >= other_placement.next_position
  end

  def ensure_attributes(voice, position, rhythmic_value, pitch)
    @voice = voice
    ensure_position(position)
    @rhythmic_value = HeadMusic::RhythmicValue.get(rhythmic_value)
    @pitch = HeadMusic::Pitch.get(pitch)
  end

  def ensure_position(position)
    @position = if position.is_a?(HeadMusic::Position)
                  position
                else
                  HeadMusic::Position.new(composition, position)
                end
  end
end
