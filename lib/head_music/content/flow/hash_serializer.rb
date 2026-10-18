class HeadMusic::Content::Flow
  # Writes a flow as the schema v5 hash that HashDeserializer reads back.
  class HashSerializer
    def initialize(flow, bars)
      @flow = flow
      @bars = bars
    end

    def to_h
      {
        "schema_version" => SCHEMA_VERSION,
        "name" => @flow.name,
        "composer" => @flow.composer&.to_s,
        "origin" => @flow.origin&.to_s,
        "work" => @flow.work&.to_h,
        "source" => @flow.source&.to_h,
        "timeline" => @flow.timeline_to_h,
        "parts" => parts_to_h,
        "bars" => @bars.serialize,
        "comments" => @flow.comments.map(&:to_h)
      }.merge(part_players_to_h)
    end

    private

    # A player is written once and each part points at it by index, so two
    # parts sharing one chair still share it when read back, and two chairs
    # that happen to share a name stay two. The key is not "players" because a
    # project document already uses that name for its own indexes.
    def part_players
      @part_players ||= @flow.parts.filter_map(&:player).uniq(&:object_id)
    end

    def part_players_to_h
      return {} if part_players.empty?

      {"part_players" => part_players.map { |player| {"name" => player.name} }}
    end

    def parts_to_h
      @flow.parts.map do |part|
        index = part.player && part_players.index { |player| player.equal?(part.player) }
        index ? part.to_h.merge("player" => index) : part.to_h
      end
    end
  end
end
