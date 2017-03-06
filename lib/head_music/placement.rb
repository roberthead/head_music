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
    position + rhythmic_value
  end

  def <=>(other)
    self.position <=> other.position
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
