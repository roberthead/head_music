class HeadMusic::Placement
  attr_reader :voice, :position, :rhythmic_value, :pitch
  delegate :composition, to: :voice

  def initialize(voice, position, rhythmic_value, pitch)
    ensure_attributes(voice, position, rhythmic_value, pitch)
  end

  def note?
    pitch
  end

  def rest?
    !note?
  end

  private

  def ensure_attributes(voice, position, rhythmic_value, pitch)
    @voice = voice
    ensure_position(position)
    @rhythmic_value = rhythmic_value
    @pitch = HeadMusic::Pitch.get(pitch)
  end

  def ensure_position(position)
    if position.is_a?(HeadMusic::Position)
      @position = position
    else
      @position = HeadMusic::Position.new(composition, position)
    end
  end
end
