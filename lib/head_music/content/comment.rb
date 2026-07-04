# A module for musical content
module HeadMusic::Content; end

# A comment is a free-text annotation, optionally anchored to a position in a composition.
class HeadMusic::Content::Comment
  attr_reader :composition, :text, :position

  def initialize(composition, text, position = nil)
    @composition = composition
    @text = text
    ensure_position(position)
  end

  def to_s
    text
  end

  private

  def ensure_position(position)
    return if position.nil?

    @position = if position.is_a?(HeadMusic::Content::Position)
      unless position.composition.equal?(composition)
        raise ArgumentError, "position belongs to a different composition"
      end
      position
    else
      HeadMusic::Content::Position.new(composition, position)
    end
  end
end
