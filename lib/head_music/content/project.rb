# A module for musical content
module HeadMusic::Content; end

# A project is the document: a set of players and the flows they play in.
#
# A project supplies only what multi-part coordination needs -- players, score
# order, and (later) layouts. Music that needs none of that is a flow standing
# on its own.
class HeadMusic::Content::Project
  SCHEMA_VERSION = HeadMusic::Content::Flow::SCHEMA_VERSION

  attr_reader :players, :flows
  attr_accessor :name

  def self.from_h(hash)
    raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

    hash = hash.deep_transform_keys(&:to_s)
    version = hash["schema_version"]
    raise ArgumentError, "unsupported schema_version: #{version.inspect} (supported: #{SCHEMA_VERSION})" unless version == SCHEMA_VERSION

    new(name: hash["name"]).tap do |project|
      Array(hash["players"]).each { |player_hash| project.add_player(name: player_hash["name"]) }
      Array(hash["flows"]).each_with_index do |flow_hash, index|
        project.adopt_flow_at(HeadMusic::Content::Flow.from_h(flow_hash), Array(hash["flows"])[index]["players"])
      end
    end
  end

  def self.from_json(json)
    from_h(JSON.parse(json))
  end

  def initialize(name: nil)
    @name = name || "Project"
    @players = []
    @flows = []
  end

  # Players keep authored order. Sorting them into score order is a score's
  # job, not the document's.
  def add_player(name: nil)
    HeadMusic::Content::Player.new(project: self, name: name).tap { |player| @players << player }
  end

  # Adopt a standalone flow, minting a player for each of its parts that has
  # none.
  #
  # This is the operation that closes the gap the model deliberately leaves
  # open: a flow may stand alone, and a part may have no player, right up until
  # a document needs chairs to coordinate. Parts that already have players keep
  # them, so adopting a flow twice changes nothing.
  #
  # @return [HeadMusic::Content::Flow] the flow, now owned
  def add_flow(flow)
    return flow if flows.any? { |owned| owned.equal?(flow) }
    raise ArgumentError, "the flow belongs to another project" if flow.project && !flow.project.equal?(self)

    @flows << flow
    flow.project = self
    flow.parts.each_with_index { |part, index| part.player ||= add_player(name: player_name_for(part, index)) }
    flow
  end

  # A flow is adopted with its parts already paired to players by index, which
  # is how the chairs survive a round trip: a player is identified by its place
  # in the project's authored order, since it has no other identity.
  #
  # @api private for Project.from_h
  def adopt_flow_at(flow, player_indexes)
    @flows << flow
    flow.project = self
    flow.parts.each_with_index do |part, index|
      player_index = Array(player_indexes)[index]
      part.player = players[player_index] if player_index
    end
    flow
  end

  def to_h
    {
      "schema_version" => SCHEMA_VERSION,
      "name" => name,
      "players" => players.map { |player| {"name" => player.name} },
      "flows" => flows.map { |flow| flow.to_h.merge("players" => player_indexes_for(flow)) }
    }
  end

  def to_json(*_args)
    to_h.to_json
  end

  def to_s
    "#{name} — #{flows.length} #{(flows.length == 1) ? "flow" : "flows"}"
  end

  private

  # Which chair each part fills, by index into the project's players. Null for
  # a part with no player, which stays a plain staff of music.
  def player_indexes_for(flow)
    flow.parts.map { |part| part.player && players.index { |player| player.equal?(part.player) } }
  end

  # Named for what the part plays, falling back to its position, because a
  # chair with no name is harder to find in a score order than a numbered one.
  def player_name_for(part, index)
    part.instrument&.name || "Part #{index + 1}"
  end
end
