# A module for musical content
module HeadMusic::Content; end

# A layout is a view of a project: which flows appear, which players appear,
# whether the pitches are sounding or written, and what the document is called.
# The music is the project's; a layout adds no content and changes none. It
# selects, and it renders.
class HeadMusic::Content::Layout
  # A score is its own class, so that it reads back as one; see Score.
  KINDS = %i[part custom].freeze

  attr_reader :project, :kind, :title_override
  # Nil when unselected, which is what serialization writes and what keeps a
  # layout answering the project's collections as members are added.
  attr_reader :selected_flows, :selected_players

  def self.attributes_from_h(hash, project:)
    hash = hash.transform_keys(&:to_s)
    {
      kind: (hash["kind"] || :custom).to_sym,
      flows: members_at(hash["flows"], project.flows),
      players: members_at(hash["players"], project.players),
      concert_pitch: hash.fetch("concert_pitch", true),
      title_override: hash["title_override"]
    }
  end

  def self.members_at(indexes, collection)
    indexes && Array(indexes).map { |index| collection[index] }
  end
  private_class_method :members_at

  def initialize(project:, kind: :custom, flows: nil, players: nil, concert_pitch: true, title_override: nil)
    ensure_known_kind!(kind)

    @project = project
    @kind = kind.to_sym
    @selected_flows = ensure_members(flows, project.flows, "flow")
    @selected_players = ensure_members(players, project.players, "player")
    @concert_pitch = concert_pitch
    @title_override = title_override
  end

  def flows
    selected_flows || project.flows
  end

  def players
    selected_players || project.players
  end

  def concert_pitch?
    !!@concert_pitch
  end

  def transposed?
    !concert_pitch?
  end

  # A selected flow in which no selected player has a part is skipped rather
  # than rendered empty: a flute part book has two movements, not a silent third.
  def rendered_flows
    flows.select { |flow| flow.parts.any? { |part| selects?(part) } }
  end

  def title
    title_override || shared_work_title || project.name
  end

  # Never memoized: a flow is mutable, and a cached view would go stale without
  # saying so.
  def realize(flow)
    Realization.new(self, flow).flow
  end

  # A selection holds only the project's players, never nil, so a part with no
  # player is kept only when nothing is selected.
  #
  # @api private for Layout::Realization
  def selects?(part)
    selected_players.nil? || selected_players.include?(part.player)
  end

  # Which of the flow's parts survive the selection, by index, in the order they
  # are written on the page. A score sorts them; see Score#kept_part_indexes.
  #
  # @api private for Layout::Realization
  def kept_part_indexes(flow)
    flow.parts.each_index.select { |index| selects?(flow.parts[index]) }
  end

  # A single-flow layout's override titles the tune itself; in a book each
  # movement keeps its own name and the override titles the document.
  #
  # @api private for Layout::Realization
  def realized_name_for(flow)
    single_flow? ? (title_override || flow.name) : flow.name
  end

  # ABC has no book-title field, so a multi-tune layout's title is not
  # rendered; each tune carries its own T:.
  def to_abc
    ensure_something_to_render!
    rendered_flows.map.with_index(1) do |flow, number|
      HeadMusic::Notation::ABC.render(realize(flow), reference_number: number, transposed: transposed?)
    end.join("\n")
  end

  # A single flow renders exactly as the flow would on its own; several render
  # as successive \score blocks under one \header.
  def to_lilypond
    ensure_something_to_render!
    realized = rendered_flows.map { |flow| realize(flow) }
    return HeadMusic::Notation::LilyPond.render(realized.first, **rendering_options) if realized.one?

    HeadMusic::Notation::LilyPond::BookWriter.new(realized, title: title, **rendering_options).to_s
  end

  def to_musicxml
    count = rendered_flows.length
    if count > 1
      raise HeadMusic::Notation::RenderError,
        "MusicXML holds one flow per document and this layout renders #{count}; use #to_musicxml_documents"
    end

    to_musicxml_documents.first
  end

  def to_musicxml_documents
    ensure_something_to_render!
    rendered_flows.map.with_index(1) do |flow, number|
      HeadMusic::Notation::MusicXML.render(realize(flow), **musicxml_options(number))
    end
  end

  def to_h
    {
      "kind" => kind.to_s,
      "title_override" => title_override,
      "concert_pitch" => concert_pitch?,
      "ensemble_type" => nil,
      "flows" => selection_indexes(selected_flows, project.flows),
      "players" => selection_indexes(selected_players, project.players)
    }
  end

  def to_s
    "#{title} — #{kind} layout of #{rendered_flows.length} #{"flow".pluralize(rendered_flows.length)}"
  end

  private

  def ensure_known_kind!(kind)
    kinds = self.class::KINDS
    return if kinds.include?(kind.to_sym)

    raise ArgumentError, "unknown layout kind: #{kind.inspect} (known: #{kinds.join(", ")})"
  end

  # Refused on entry: a stray member would otherwise serialize as an absence
  # and surface only when the layout was rendered.
  def ensure_members(selection, collection, noun)
    return nil if selection.nil?

    unknown = selection.reject { |member| collection.any? { |candidate| candidate.equal?(member) } }
    raise ArgumentError, "the layout selects a #{noun} the project does not hold" unless unknown.empty?

    selection
  end

  def single_flow?
    rendered_flows.one?
  end

  # A document standing alone names only itself, which is what keeps a one-flow
  # layout byte-identical to the flow's own output.
  def musicxml_options(movement_number)
    return rendering_options if single_flow?

    rendering_options.merge(work_title: title, movement_number: movement_number)
  end

  def rendering_options
    {transposed: transposed?, arranger: arranger}
  end

  # The project's arrangers, joined as the composer is: this version's credit,
  # which is why a flow rendering on its own has none to print.
  def arranger
    names = project.credits.names(:arranger)
    names.join(", ") unless names.empty?
  end

  def ensure_something_to_render!
    return unless rendered_flows.empty?

    raise HeadMusic::Notation::RenderError, "the layout selects no flow that any selected player has a part in"
  end

  def shared_work_title
    works = flows.map(&:work).uniq
    works.first&.title if works.size == 1
  end

  # Positions, not objects: a player and a flow are identified in a document
  # by their place in the project's authored order.
  def selection_indexes(selection, collection)
    selection&.map { |member| collection.index { |candidate| candidate.equal?(member) } }
  end
end
