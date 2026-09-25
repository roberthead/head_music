# A module for musical content
module HeadMusic::Content; end

class HeadMusic::Content::Layout
  # A layout's view of one flow, as a flow of its own: the source is serialized,
  # the hash edited, and a new flow read back. A derived flow is a real flow, so
  # the writers, render plans, and preflights know nothing about layouts, and
  # Flow#to_h's fresh hashes keep the source untouched.
  class Realization
    attr_reader :layout, :source

    def initialize(layout, source)
      @layout = layout
      @source = source
    end

    def flow
      HeadMusic::Content::Flow.from_h(realized_hash).tap { |realized| attach_players(realized) }
    end

    private

    def realized_hash
      hash = source.to_h
      hash["name"] = layout.realized_name_for(source)
      hash["parts"] = kept_indexes.map { |index| realized_part(hash["parts"][index], source.parts[index]) }
      hash
    end

    # Computed from the live parts rather than from the hash, which carries
    # player names but not the project's player objects.
    def kept_indexes
      @kept_indexes ||= layout.kept_part_indexes(source)
    end

    # The timeline is left in concert pitch: it is one timeline and a mixed
    # ensemble has as many written keys as it has transpositions, so the written
    # key is derived per part at render time (see Notation::RenderPlan).
    def realized_part(part_hash, part)
      return part_hash if layout.concert_pitch?

      part_hash.merge("voices" => part_hash["voices"].map { |voice_hash| written_voice(voice_hash, part) })
    end

    def written_voice(voice_hash, part)
      voice_hash.merge("placements" => voice_hash["placements"].map { |placement_hash| written_placement(placement_hash, part) })
    end

    def written_placement(placement_hash, part)
      sounds = placement_hash["sounds"]
      return placement_hash if sounds.empty?

      transposition = HeadMusic::Content::Layout::Transposition.for(part.instrument_at(bar_number_of(placement_hash)))
      return placement_hash if transposition.identity?

      placement_hash.merge("sounds" => sounds.map { |sound| transposition.written_sound(sound) })
    end

    # A position serializes as "bar:count:tick:subtick".
    def bar_number_of(placement_hash)
      placement_hash["position"].to_s.split(":").first.to_i
    end

    # The read mints players from their names, but a layout selects the
    # project's own objects, so the chairs are put back by position.
    def attach_players(realized)
      realized.parts.each_with_index do |part, index|
        part.player = source.parts[kept_indexes[index]].player
      end
    end
  end
end
