# A module for music rudiments
module HeadMusic::Rudiment; end

# A Note is a fundamental musical element consisting of a pitch and a duration.
# This is the rudiment version, representing the abstract concept of a note
# independent of where it is placed in a flow.
#
# For notes placed within a flow context, see HeadMusic::Content::Note
class HeadMusic::Rudiment::Note < HeadMusic::Rudiment::RhythmicElement
  include HeadMusic::Named

  attr_reader :pitch

  delegate :spelling, :register, :letter_name, :alteration, to: :pitch
  delegate :sharp?, :flat?, :natural?, to: :pitch
  delegate :pitch_class, :midi_note_number, :frequency, to: :pitch

  # Regex pattern for parsing note strings like "C#4 quarter" or "Eb3 dotted half"
  # Extract the core pattern from Spelling::MATCHER without anchors.
  #
  # The alteration group wraps the whole pattern in (?:...) before making it
  # optional. Interpolating "#{...}?" instead binds the "?" to the pattern's final
  # alternative alone, which truncates "C##4" to a bare "C#" and loses the register.
  PITCH_PATTERN = /([A-G])((?:#{HeadMusic::Rudiment::Alteration::PATTERN.source})?)(-?\d+)?/i
  MATCHER = /^\s*(#{PITCH_PATTERN.source})\s+(.+)$/i

  def self.get(pitch, rhythmic_duration = nil)
    return pitch if pitch.is_a?(HeadMusic::Rudiment::Note)
    return get_from_string(pitch) if rhythmic_duration.nil? && pitch.is_a?(String)

    pitch = HeadMusic::Rudiment::Pitch.get(pitch)
    rhythmic_duration = HeadMusic::Rudiment::RhythmicDuration.get(rhythmic_duration || :quarter)
    return nil unless rhythmic_duration

    fetch_or_create(pitch, rhythmic_duration)
  end

  # Parse a lone string as "pitch rhythmic_duration" (e.g., "F#4 dotted-quarter"),
  # falling back to just a pitch with a default quarter note.
  def self.get_from_string(string)
    match = string.match(MATCHER)
    if match
      pitch_obj = HeadMusic::Rudiment::Pitch.get(match[1])
      rhythmic_duration_obj = HeadMusic::Rudiment::RhythmicDuration.get(match[5])
      return fetch_or_create(pitch_obj, rhythmic_duration_obj) if pitch_obj && rhythmic_duration_obj
    end

    pitch_obj = HeadMusic::Rudiment::Pitch.get(string)
    return fetch_or_create(pitch_obj, HeadMusic::Rudiment::RhythmicDuration.get(:quarter)) if pitch_obj

    nil
  end

  def self.fetch_or_create(pitch, rhythmic_duration)
    hash_key = [pitch.to_s, rhythmic_duration.to_s].join("_")
    fetch_or_register(hash_key, pitch, rhythmic_duration)
  end

  def initialize(pitch, rhythmic_duration)
    super(rhythmic_duration)
    @pitch = pitch
  end

  # Make new public for this concrete class
  public_class_method :new

  def name
    "#{pitch} #{rhythmic_duration}"
  end

  def to_s
    name
  end

  def ==(other)
    other = HeadMusic::Rudiment::Note.get(other)
    super && pitch == other.pitch
  end

  def <=>(other)
    return nil unless other.is_a?(HeadMusic::Rudiment::RhythmicElement)
    return super unless other.is_a?(self.class)

    [rhythmic_duration, pitch] <=> [other.rhythmic_duration, other.pitch]
  end

  # Transpose the note up by an interval or semitones
  def +(other)
    new_pitch = pitch + other
    self.class.get(new_pitch, rhythmic_duration)
  end

  # Transpose the note down by an interval or semitones
  def -(other)
    new_pitch = pitch - other
    self.class.get(new_pitch, rhythmic_duration)
  end

  # Override to maintain pitch when changing rhythmic duration
  def with_rhythmic_duration(new_rhythmic_duration)
    self.class.get(pitch, new_rhythmic_duration)
  end

  # Change the pitch while keeping the same rhythmic duration
  def with_pitch(new_pitch)
    self.class.get(new_pitch, rhythmic_duration)
  end

  def sounded?
    true
  end

  private_class_method :fetch_or_create, :get_from_string
end
