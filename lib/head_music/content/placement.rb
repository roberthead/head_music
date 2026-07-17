# A module for musical content
module HeadMusic::Content; end

# A placement is a note, chord, or rest at a position within a voice in a composition
class HeadMusic::Content::Placement
  include Comparable

  attr_reader :voice, :position, :rhythmic_value, :pitches

  delegate :composition, to: :voice
  delegate :spelling, to: :pitch, allow_nil: true

  def initialize(voice, position, rhythmic_value, pitch_or_pitches = nil)
    ensure_attributes(voice, position, rhythmic_value, pitch_or_pitches)
  end

  # The top pitch of a chord (or the only pitch of a note), which melodic
  # analysis treats as the melody note. Enharmonic ties resolve to the
  # first-listed pitch (MRI's max keeps the earliest of equals; a spec
  # pins the behavior).
  def pitch
    pitches.max
  end

  def note?
    pitches.any?
  end

  def chord?
    pitches.length > 1
  end

  def rest?
    !note?
  end

  # Voice#place merges a same-position placement into the existing one, so a
  # position holds at most one placement. The pitch union keeps the chord free
  # of duplicates, making repeated placement of a pitch idempotent.
  def merge(other)
    unless rhythmic_value == other.rhythmic_value
      raise ArgumentError,
        "cannot place a #{other.rhythmic_value} at #{position}: position occupied by a #{rhythmic_value}"
    end

    @pitches = (pitches + other.pitches).uniq.freeze
    self
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
    "#{rhythmic_value} #{pitches.any? ? pitches.join(" ") : "rest"} at #{position}"
  end

  def to_h
    {
      "position" => position.to_s,
      "rhythmic_value" => rhythmic_value.to_s,
      "pitches" => pitches.map(&:to_s)
    }
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

  def ensure_attributes(voice, position, rhythmic_value, pitch_or_pitches)
    @voice = voice
    ensure_position(position)
    @rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(rhythmic_value)
    @pitches = ensure_pitches(pitch_or_pitches)
  end

  # A bare unparseable pitch quietly becomes a rest (long-standing leniency),
  # but an array is explicit chord input, so an unparseable element raises
  # rather than silently thinning the chord. uniq keeps chords duplicate-free.
  def ensure_pitches(pitch_or_pitches)
    return [HeadMusic::Rudiment::Pitch.get(pitch_or_pitches)].compact.freeze unless pitch_or_pitches.is_a?(Array)

    pitch_or_pitches.map { |value| fetch_pitch(value) }.uniq.freeze
  end

  def fetch_pitch(value)
    pitch = HeadMusic::Rudiment::Pitch.get(value)
    raise ArgumentError, "unknown pitch #{value.inspect}" unless pitch

    pitch
  end

  def ensure_position(position)
    @position = if position.is_a?(HeadMusic::Content::Position)
      position
    else
      HeadMusic::Content::Position.new(composition, position)
    end
  end
end
