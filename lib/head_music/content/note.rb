# A module for musical content
module HeadMusic::Content; end

# A note is a pitch with a duration.
#
# Note quacks like a placement, but requires a different set of construction arguments
#   - always has a pitch
#   - receives a voice and position if unspecified
class HeadMusic::Content::Note
  attr_accessor :pitch, :rhythmic_value, :voice, :position

  def initialize(pitch, rhythmic_value, voice = nil, position = nil)
    @pitch = HeadMusic::Pitch.get(pitch)
    @rhythmic_value = HeadMusic::Content::RhythmicValue.get(rhythmic_value)
    @voice = voice || HeadMusic::Content::Voice.new
    @position = position || HeadMusic::Content::Position.new(@voice.composition, "1:1")
  end

  def placement
    @placement ||= HeadMusic::Content::Placement.new(voice, position, rhythmic_value, pitch)
  end

  def to_s
    "#{pitch} at #{position}"
  end

  def method_missing(method_name, *args, &block)
    respond_to_missing?(method_name) ? placement.send(method_name, *args, &block) : super
  end

  def respond_to_missing?(method_name, *_args)
    placement.respond_to?(method_name)
  end
end
