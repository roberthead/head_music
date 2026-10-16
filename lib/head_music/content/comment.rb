# A module for musical content
module HeadMusic::Content; end

# A comment is a free-text annotation, optionally anchored to a position in a flow.
class HeadMusic::Content::Comment
  attr_reader :flow, :text, :position

  def initialize(flow, text, position = nil)
    @flow = flow
    @text = text
    @position = position && HeadMusic::Content::Position.for_flow(flow, position)
  end

  def to_s
    text
  end

  def to_h
    {"text" => text, "position" => position&.to_s}
  end
end
