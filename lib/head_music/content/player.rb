# A module for musical content
module HeadMusic::Content; end

# A player is a chair in a project: "Flute 1", "Piano".
#
# The chair is project-level and the music is per-flow, which is what makes
# "the flute plays in movements 1 and 3" expressible without a nullable join --
# there is simply no part for that player in movement 2 -- and what makes an
# instrument change within a part honest, since conceptually it is still the
# same player.
class HeadMusic::Content::Player
  attr_reader :project
  attr_accessor :name

  def initialize(project: nil, name: nil)
    @project = project
    @name = name
  end

  # This player's parts across the project's flows, in flow order.
  def parts
    return [] if project.nil?

    project.flows.flat_map(&:parts).select { |part| part.player == self }
  end

  # Every instrument this player plays, across the project's flows.
  #
  # Derived rather than stored: a stored field would drift from the parts that
  # actually carry the instrument, and an instrument change lives on a part.
  def instruments
    parts.flat_map(&:instruments).uniq
  end

  # What this player picks up first: the instrument in force at the opening of
  # their first part. What a score order sorts by.
  def primary_instrument
    parts.first&.instrument
  end

  def to_s
    name.to_s
  end
end
