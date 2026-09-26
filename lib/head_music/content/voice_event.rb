# A module for musical content
module HeadMusic::Content; end

# A voice event is a note, chord, or rest at a position within a voice in a
# flow. Each one fills time, so a voice's events run end to end. It is
# abstract: a NoteEvent sounds and a RestEvent is silent, and .build answers
# whichever the sounds call for.
class HeadMusic::Content::VoiceEvent
  include Comparable

  attr_reader :voice, :position, :rhythmic_value

  # Authored beam grouping relative to the previous voice event, set after
  # construction (the Bar-style side-metadata pattern). Tri-state: nil = use
  # the meter-derived default, true = force a beam break before this event,
  # false = force a beam join to the previous event. Consumed by the
  # MusicXML writer, which prefers it over the default grouping.
  attr_accessor :beam_break_before

  delegate :flow, to: :voice
  delegate :spelling, to: :pitch, allow_nil: true

  private_class_method :new

  def self.build(voice, position, rhythmic_value, sound_or_sounds = nil)
    sounds = HeadMusic::Content::SoundResolver.resolve(sound_or_sounds)
    return HeadMusic::Content::RestEvent.new(voice, position, rhythmic_value) if sounds.empty?

    HeadMusic::Content::NoteEvent.new(voice, position, rhythmic_value, sounds)
  end

  def initialize(voice, position, rhythmic_value)
    @voice = voice
    ensure_position(position)
    @rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(rhythmic_value)
  end

  def sounds
    []
  end

  def pitches
    sounds.select(&:pitched?)
  end

  # Authored sung text: at most one Syllable per verse, keyed by verse number.
  # Only a NoteEvent sings; the rest have none.
  def syllables
    {}
  end

  def syllable(verse = 1)
    syllables[verse]
  end

  def sung?
    syllables.any?
  end

  # Markings written on the event. Only a NoteEvent carries them; the rest
  # have none, so readers and writers need not ask which kind they hold.
  def articulations
    []
  end

  def ornaments
    []
  end

  def note_dynamic
    nil
  end

  # The top pitch of a chord (or the only pitch of a note), which melodic
  # analysis treats as the melody note. Returns nil for rests and
  # unpitched-only events; pitched? is the guard. Enharmonic ties
  # resolve to the first-listed pitch (MRI's max keeps the earliest of
  # equals; a spec pins the behavior).
  def pitch
    pitches.max
  end

  def rest?
    false
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

  def next_position
    @next_position ||= position + rhythmic_value
  end

  def <=>(other)
    position <=> other.position
  end

  def during?(other_event)
    starts_during?(other_event) || ends_during?(other_event) || wraps?(other_event)
  end

  def to_s
    "#{rhythmic_value} #{sounds.any? ? sounds.map { |sound| sound_label(sound) }.join(" ") : "rest"} at #{position}"
  end

  def inspect
    "#<#{self.class.name} #{self}>"
  end

  def to_h
    hash = {
      "position" => position.to_s,
      "rhythmic_value" => rhythmic_value.to_s,
      "sounds" => sounds.map { |sound| sound_datum(sound) }
    }
    hash["beam_break_before"] = beam_break_before unless beam_break_before.nil?
    hash["syllables"] = syllables.keys.sort.map { |verse| syllables[verse].to_h } unless syllables.empty?
    hash["articulations"] = articulations.map(&:name_key) unless articulations.empty?
    hash["ornaments"] = ornaments.map(&:name_key) unless ornaments.empty?
    hash["note_dynamic"] = note_dynamic.name_key if note_dynamic
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

  def starts_during?(other_event)
    position >= other_event.position && position < other_event.next_position
  end

  def ends_during?(other_event)
    next_position > other_event.position && next_position <= other_event.next_position
  end

  def wraps?(other_event)
    position <= other_event.position && next_position >= other_event.next_position
  end

  def ensure_position(position)
    @position = if position.is_a?(HeadMusic::Content::Position)
      position
    else
      HeadMusic::Content::Position.new(flow, position)
    end
  end
end
