# A module for music rudiments
module HeadMusic::Rudiment; end

# A Note is a fundamental musical element consisting of a pitch and a duration.
# This is the rudiment version, representing the abstract concept of a note
# independent of its placement in a composition.
#
# For notes placed within a composition context, see HeadMusic::Content::Note
class HeadMusic::Rudiment::Note
  include HeadMusic::Named
  include HeadMusic::Parsable
  include Comparable

  attr_reader :pitch, :rhythmic_value

  delegate :spelling, :register, :letter_name, :alteration, to: :pitch
  delegate :sharp?, :flat?, to: :pitch
  delegate :pitch_class, :midi_note_number, :frequency, to: :pitch
  delegate :unit, :dots, :tied_value, to: :rhythmic_value
  delegate :duration, :beats, to: :rhythmic_value

  # Regex pattern for parsing note strings like "C#4 quarter" or "Eb3 dotted half"
  # Extract the core pattern from Spelling::MATCHER without anchors
  PITCH_PATTERN = /([A-G])(#{HeadMusic::Rudiment::Alteration::MATCHER.source}?)(-?\d+)?/i
  MATCHER = /^\s*(#{PITCH_PATTERN.source})\s+(.+)$/i

  def self.get(pitch, rhythmic_value = nil)
    return pitch if pitch.is_a?(HeadMusic::Rudiment::Note)

    if rhythmic_value.nil? && pitch.is_a?(String)
      # Try to parse as a complete note string first
      parsed = parse(pitch)
      return parsed if parsed

      # If parsing fails, treat it as just a pitch with default quarter note
      pitch_obj = HeadMusic::Rudiment::Pitch.get(pitch)
      return fetch_or_create(pitch_obj, HeadMusic::Content::RhythmicValue.get(:quarter)) if pitch_obj

      nil
    else
      pitch = HeadMusic::Rudiment::Pitch.get(pitch)
      rhythmic_value = HeadMusic::Content::RhythmicValue.get(rhythmic_value || :quarter)
      fetch_or_create(pitch, rhythmic_value)
    end
  end

  def self.fetch_or_create(pitch, rhythmic_value)
    @notes ||= {}
    hash_key = [pitch.to_s, rhythmic_value.to_s].join("_")
    @notes[hash_key] ||= new(pitch, rhythmic_value)
  end

  def self.from_string(string)
    match = string.match(MATCHER)
    return nil unless match

    # The captures include the full pitch pattern and its subgroups
    captures = match.captures
    pitch_string = captures[0]  # Full pitch match
    rhythm_string = captures[-1]  # Last capture is the rhythm

    pitch = HeadMusic::Rudiment::Pitch.get(pitch_string)
    rhythmic_value = HeadMusic::Content::RhythmicValue.get(rhythm_string.strip)

    return nil unless pitch && rhythmic_value
    fetch_or_create(pitch, rhythmic_value)
  end

  def self.from_pitch(pitch)
    return nil unless pitch.is_a?(HeadMusic::Rudiment::Pitch)
    fetch_or_create(pitch, HeadMusic::Content::RhythmicValue.get(:quarter))
  end

  def self.from_pitched_item(input)
    from_pitch(input)
  end

  def initialize(pitch, rhythmic_value)
    @pitch = pitch
    @rhythmic_value = rhythmic_value
  end

  def name
    "#{pitch} #{rhythmic_value}"
  end

  def to_s
    name
  end

  def ==(other)
    return false unless other.is_a?(HeadMusic::Rudiment::Note)
    pitch == other.pitch && rhythmic_value == other.rhythmic_value
  end

  def <=>(other)
    return nil unless other.is_a?(HeadMusic::Rudiment::Note)

    # First compare by pitch
    pitch_comparison = pitch <=> other.pitch
    return pitch_comparison unless pitch_comparison == 0

    # If pitches are equal, compare by rhythmic value
    rhythmic_value <=> other.rhythmic_value
  end

  # Transpose the note up by an interval or semitones
  def +(other)
    new_pitch = pitch + other
    self.class.get(new_pitch, rhythmic_value)
  end

  # Transpose the note down by an interval or semitones
  def -(other)
    new_pitch = pitch - other
    self.class.get(new_pitch, rhythmic_value)
  end

  # Change the rhythmic value while keeping the same pitch
  def with_rhythmic_value(new_rhythmic_value)
    self.class.get(pitch, new_rhythmic_value)
  end

  # Change the pitch while keeping the same rhythmic value
  def with_pitch(new_pitch)
    self.class.get(new_pitch, rhythmic_value)
  end

  def natural?
    spelling.natural?
  end

  private_class_method :new
end
