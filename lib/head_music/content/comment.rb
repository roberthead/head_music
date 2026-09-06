# A module for musical content
module HeadMusic::Content; end

# A comment is a free-text annotation, optionally anchored to a position in a flow.
class HeadMusic::Content::Comment
  attr_reader :flow, :text, :position

  def initialize(flow, text, position = nil)
    @flow = flow
    @text = text
    ensure_position(position)
  end

  def to_s
    text
  end

  def to_h
    {"text" => text, "position" => position&.to_s}
  end

  private

  def ensure_position(position)
    return if position.nil?

    @position = if position.is_a?(HeadMusic::Content::Position)
      unless position.flow.equal?(flow)
        raise ArgumentError, "position belongs to a different flow"
      end
      position
    else
      HeadMusic::Content::Position.new(flow, position)
    end
  end
end
