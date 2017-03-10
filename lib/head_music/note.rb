class HeadMusic::Note
  attr_accessor :pitch, :rhythmic_value, :voice, :position

  def initialize(pitch, rhythmic_value, voice = nil, position = nil)
    @pitch = HeadMusic::Pitch.get(pitch)
    @rhythmic_value = HeadMusic::RhythmicValue.get(rhythmic_value)
    @voice = voice || Voice.new
    @position = position || HeadMusic::Position.new(@voice.composition, '1:1')
  end

  def placement
    @placement ||= HeadMusic::Placement.new(voice, position, rhythmic_value, pitch)
  end

  def method_missing(method_name, *args, &block)
    placement.send(method_name, *args, &block)
  end
end
