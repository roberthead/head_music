# A module for musical content
module HeadMusic::Content; end

# A dynamic event puts a dynamic level, such as p or ff, in force at a
# position. It takes no time, so it is kept apart from the voice events that
# fill a voice, and it may fall anywhere, even under a held note or a rest.
class HeadMusic::Content::DynamicEvent
  attr_reader :flow, :position, :level

  delegate :name_key, to: :level

  def initialize(flow, position, level)
    @flow = flow
    @level = level_for(level)
    ensure_position(position)
  end

  def to_s
    "#{name_key} at #{position}"
  end

  def inspect
    "#<#{self.class.name} #{self}>"
  end

  def to_h
    {"position" => position.to_s, "level" => name_key}
  end

  private

  def level_for(identifier)
    dynamic = HeadMusic::Rudiment::Dynamic.get(identifier)
    raise ArgumentError, "unknown dynamic: #{identifier.inspect}" unless dynamic
    unless dynamic.level?
      raise ArgumentError, "#{dynamic.name_key} is an accent, not a level; set it as a note event's note_dynamic"
    end

    dynamic
  end

  def ensure_position(position)
    @position = if position.is_a?(HeadMusic::Content::Position)
      raise ArgumentError, "position belongs to a different flow" unless position.flow.equal?(flow)

      position
    else
      HeadMusic::Content::Position.new(flow, position)
    end
  end
end
