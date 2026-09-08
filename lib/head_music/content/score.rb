# A module for musical content
module HeadMusic::Content; end

# A score is the layout that shows the players together: everyone's music on
# one system, in the order and the grouping the ensemble conventionally puts
# them in.
class HeadMusic::Content::Score < HeadMusic::Content::Layout
  KINDS = %i[score].freeze

  attr_reader :ensemble_type

  def self.attributes_from_h(hash, project:)
    hash = hash.transform_keys(&:to_s)
    super.merge(ensemble_type: hash["ensemble_type"]&.to_sym)
  end

  def initialize(project:, ensemble_type: nil, **layout_kwargs)
    @ensemble_type = ensemble_type&.to_sym
    ensure_known_ensemble_type!
    super(project: project, **layout_kwargs, kind: :score)
  end

  def score_order
    return nil if ensemble_type.nil?

    @score_order ||= HeadMusic::Instruments::ScoreOrder.get(ensemble_type)
  end

  # A permutation of this layout's players, never a selection. Chairs the order
  # does not place come last in authored order, and ties among equals keep
  # authored order too, so two clarinets stay first and second.
  def ordered_players
    return players if score_order.nil?

    placed, unplaced = players.each_with_index.partition { |player, _index| position_of(player) }
    placed.sort_by { |player, index| [position_of(player), index] }.map(&:first) + unplaced.map(&:first)
  end

  # The sections a score brackets, in score order, each holding its players.
  # Unplaced chairs group under a nil section key.
  def player_groups
    # slice_when rather than chunk, which drops the nil-keyed run that the
    # unplaced chairs belong to.
    ordered_players
      .slice_when { |one, other| section_key_of(one) != section_key_of(other) }
      .map { |members| [section_key_of(members.first), members] }
  end

  def to_h
    super.merge("ensemble_type" => ensemble_type&.to_s)
  end

  # A score reads top to bottom in score order, so its parts are realized in
  # that order rather than in the order they were authored.
  #
  # @api private for Layout::Realization
  def kept_part_indexes(flow)
    order = ordered_players
    super.sort_by { |index| [rank_of(flow.parts[index], order), index] }
  end

  private

  def position_of(player)
    score_order.position_of(player.primary_instrument)
  end

  def section_key_of(player)
    score_order&.section_key_of(player.primary_instrument)
  end

  # A part whose chair this score does not place keeps its authored place at
  # the bottom, which is where an unplaced chair sits in #ordered_players too.
  def rank_of(part, order)
    index = part.player && order.index { |player| player.equal?(part.player) }
    index || order.length
  end

  def ensure_known_ensemble_type!
    return if ensemble_type.nil? || HeadMusic::Instruments::ScoreOrder.get(ensemble_type)

    known = HeadMusic::Instruments::ScoreOrder::SCORE_ORDERS.keys.join(", ")
    raise ArgumentError, "unknown ensemble type: #{ensemble_type.inspect} (known: #{known})"
  end
end
