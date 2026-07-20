# A module for musical content
module HeadMusic::Content; end

# A placement is a note, chord, or rest at a position within a voice in a composition
class HeadMusic::Content::Placement
  include Comparable

  attr_reader :voice, :position, :rhythmic_value, :sounds

  # Authored beam grouping relative to the previous placement, set after
  # construction (the Bar-style side-metadata pattern). Tri-state: nil = use
  # the meter-derived default, true = force a beam break before this placement,
  # false = force a beam join to the previous placement. Consumed by the
  # MusicXML writer, which prefers it over the default grouping.
  attr_accessor :beam_break_before

  delegate :composition, to: :voice
  delegate :spelling, to: :pitch, allow_nil: true

  def initialize(voice, position, rhythmic_value, sound_or_sounds = nil)
    ensure_attributes(voice, position, rhythmic_value, sound_or_sounds)
  end

  def pitches
    sounds.select(&:pitched?)
  end

  # The top pitch of a chord (or the only pitch of a note), which melodic
  # analysis treats as the melody note. Returns nil for rests and
  # unpitched-only placements; pitched? is the guard. Enharmonic ties
  # resolve to the first-listed pitch (MRI's max keeps the earliest of
  # equals; a spec pins the behavior).
  def pitch
    pitches.max
  end

  def rest?
    sounds.empty?
  end

  def sounded?
    sounds.any?
  end

  def note?
    sounds.length == 1
  end

  def pitched_note?
    note? && pitched?
  end

  def unpitched_note?
    note? && !pitched?
  end

  def chord?
    pitches.length > 1
  end

  def pitched?
    sounds.any?(&:pitched?)
  end

  # Voice#place merges a same-position placement into the existing one, so a
  # position holds at most one placement. The sound union keeps the chord free
  # of duplicates, making repeated placement of a sound idempotent.
  def merge(other)
    unless rhythmic_value == other.rhythmic_value
      raise ArgumentError,
        "cannot place a #{other.rhythmic_value} at #{position}: position occupied by a #{rhythmic_value}"
    end

    @sounds = (sounds + other.sounds).uniq.freeze
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
    "#{rhythmic_value} #{sounds.any? ? sounds.map { |sound| sound_label(sound) }.join(" ") : "rest"} at #{position}"
  end

  def to_h
    hash = {
      "position" => position.to_s,
      "rhythmic_value" => rhythmic_value.to_s,
      "sounds" => sounds.map { |sound| sound_datum(sound) }
    }
    hash["beam_break_before"] = beam_break_before unless beam_break_before.nil?
    hash
  end

  private

  # Unpitched names may be multi-word, so they are bracketed to keep the
  # space-delimited sound list unambiguous.
  def sound_label(sound)
    sound.pitched? ? sound.to_s : "[#{sound}]"
  end

  def sound_datum(sound)
    sound.pitched? ? sound.to_s : {"unpitched" => sound.name_key&.to_s}
  end

  def starts_during?(other_placement)
    position >= other_placement.position && position < other_placement.next_position
  end

  def ends_during?(other_placement)
    next_position > other_placement.position && next_position <= other_placement.next_position
  end

  def wraps?(other_placement)
    position <= other_placement.position && next_position >= other_placement.next_position
  end

  def ensure_attributes(voice, position, rhythmic_value, sound_or_sounds)
    @voice = voice
    ensure_position(position)
    @rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(rhythmic_value)
    @sounds = ensure_sounds(sound_or_sounds)
  end

  def ensure_sounds(sound_or_sounds)
    return [].freeze if sound_or_sounds.nil?

    values = sound_or_sounds.is_a?(Array) ? sound_or_sounds : [sound_or_sounds]
    values.map { |value| resolve_sound(value) }.uniq.freeze
  end

  def resolve_sound(value)
    return value if value.is_a?(HeadMusic::Rudiment::UnpitchedSound)
    return HeadMusic::Rudiment::UnpitchedSound.get(value) if value.is_a?(HeadMusic::Instruments::Instrument)

    pitch = HeadMusic::Rudiment::Pitch.get(value)
    return pitch if pitch

    unpitched_sound(value) || raise(ArgumentError, unknown_sound_message(value))
  end

  # A bare name resolves to a percussive hit only on an unpitched instrument;
  # naming a pitched instrument is ambiguous, so it raises instead.
  # UnpitchedSound.get(nil) is the generic sound, so nil is excluded here to
  # preserve nil-as-rest at the argument level and nil-raises inside arrays.
  def unpitched_sound(value)
    return nil if value.nil?

    sound = HeadMusic::Rudiment::UnpitchedSound.get(value)
    return nil unless sound&.instrument
    return nil if sound.instrument.pitched?

    sound
  end

  def unknown_sound_message(value)
    if HeadMusic::Instruments::Instrument.get(value)&.pitched?
      "#{value.inspect} is a pitched instrument; place a pitch such as \"D4\", " \
        "or pass HeadMusic::Rudiment::UnpitchedSound.get(#{value.inspect}) for a percussive hit"
    else
      "unknown sound: #{value.inspect}"
    end
  end

  def ensure_position(position)
    @position = if position.is_a?(HeadMusic::Content::Position)
      position
    else
      HeadMusic::Content::Position.new(composition, position)
    end
  end
end
