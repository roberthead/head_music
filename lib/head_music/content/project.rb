# A module for musical content
module HeadMusic::Content; end

# A project is the document: a set of players and the flows they play in. It
# supplies only what multi-part coordination needs -- players, score order, and
# layouts. Music that needs none of that is a flow standing on its own.
class HeadMusic::Content::Project
  SCHEMA_VERSION = HeadMusic::Content::Flow::SCHEMA_VERSION

  attr_reader :players, :flows, :layouts, :credits
  attr_accessor :name

  def self.from_h(hash)
    raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

    hash = hash.deep_transform_keys(&:to_s)
    version = hash["schema_version"]
    raise ArgumentError, "unsupported schema_version: #{version.inspect} (supported: #{SCHEMA_VERSION})" unless version == SCHEMA_VERSION

    new(name: hash["name"], credits: Array(hash["credits"])).tap do |project|
      Array(hash["players"]).each { |player_hash| project.add_player(name: player_hash["name"]) }
      Array(hash["flows"]).each do |flow_hash|
        project.adopt_flow_at(HeadMusic::Content::Flow.from_h(flow_hash), flow_hash["players"])
      end
      # Layouts last: a layout selects flows and players by index, so both
      # collections must be in place before one can be resolved.
      Array(hash["layouts"]).each { |layout_hash| project.add_layout_from_h(layout_hash) }
    end
  end

  def self.from_json(json)
    from_h(JSON.parse(json))
  end

  def initialize(name: nil, credits: [])
    @name = name || "Project"
    @players = []
    @flows = []
    @layouts = []
    @credits = HeadMusic::Content::Credits.new(:project, credits)
  end

  # This version's people, as distinct from the work's composer.
  def add_credit(person, role)
    @credits = credits.add(person, role)
  end

  def works
    flows.filter_map(&:work).uniq
  end

  # Players keep authored order. Sorting them into score order is a score's
  # job, not the document's.
  def add_player(name: nil)
    HeadMusic::Content::Player.new(project: self, name: name).tap { |player| @players << player }
  end

  # Adopt a standalone flow, minting a player for each of its parts that has
  # none. This closes the gap the model leaves open: a flow may stand alone and
  # a part may have no player until a document needs chairs to coordinate.
  # Parts that already have players keep them, so adopting twice changes nothing.
  def add_flow(flow)
    return flow if flows.any? { |owned| owned.equal?(flow) }
    raise ArgumentError, "the flow belongs to another project" if flow.project && !flow.project.equal?(self)

    @flows << flow
    flow.project = self
    flow.parts.each_with_index { |part, index| part.player ||= add_player(name: player_name_for(part, index)) }
    flow
  end

  # The project holds its layouts but renders nothing itself -- rendering is a
  # layout's job.
  def add_layout(kind: :custom, **kwargs)
    return add_score(**kwargs) if kind.to_sym == :score

    hold_layout(HeadMusic::Content::Layout.new(project: self, kind: kind, **kwargs))
  end

  def add_score(ensemble_type: nil, **kwargs)
    hold_layout(HeadMusic::Content::Score.new(project: self, ensemble_type: ensemble_type, **kwargs))
  end

  # @api private for Project.from_h
  def add_layout_from_h(layout_hash)
    klass = (layout_hash["kind"].to_s == "score") ? HeadMusic::Content::Score : HeadMusic::Content::Layout
    add_layout(**klass.attributes_from_h(layout_hash, project: self))
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
      "credits" => credits.to_h,
      "players" => players.map { |player| {"name" => player.name} },
      "flows" => flows.map { |flow| flow.to_h.merge("players" => player_indexes_for(flow)) },
      "layouts" => layouts.map(&:to_h)
    }
  end

  def to_json(*_args)
    to_h.to_json
  end

  def to_s
    "#{name} — #{flows.length} #{"flow".pluralize(flows.length)}"
  end

  private

  def hold_layout(layout)
    @layouts << layout
    layout
  end

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
