# A module for musical content
module HeadMusic::Content; end

# A note is a pitch with a duration.
#
# Note quacks like a voice event, but requires a different set of construction arguments
#   - always has a pitch
#   - receives a voice and position if unspecified
class HeadMusic::Content::Note
  attr_accessor :pitch, :rhythmic_value, :voice, :position

  def initialize(pitch, rhythmic_value, voice = nil, position = nil)
    @pitch = HeadMusic::Rudiment::Pitch.get(pitch)
    @rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(rhythmic_value)
    @voice = voice || HeadMusic::Content::Voice.new
    @position = position || HeadMusic::Content::Position.new(@voice.flow, "1:1")
  end

  def voice_event
    @voice_event ||= HeadMusic::Content::NoteEvent.new(voice, position, rhythmic_value, pitch)
  end

  def to_s
    "#{pitch} at #{position}"
  end

  def method_missing(method_name, *args, &block)
    respond_to_missing?(method_name) ? voice_event.send(method_name, *args, &block) : super
  end

  def respond_to_missing?(method_name, *_args)
    voice_event.respond_to?(method_name)
  end
end
