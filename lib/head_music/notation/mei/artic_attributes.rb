module HeadMusic::Notation::MEI
  # The @artic list of a note, a chord, or a grace note. A chord carries it
  # rather than its notes, and a tied or bar-split event only on its first
  # written piece.
  class ArticAttributes
    ARTICS = {
      "staccato" => "stacc",
      "staccatissimo" => "stacciss",
      "accent" => "acc",
      "tenuto" => "ten",
      "marcato" => "marc"
    }.freeze

    def initialize(plan)
      @plan = plan
    end

    def event_attributes(node)
      return {} unless carrier?(node)

      articulations = node.grace? ? node.grace.articulations : node.item.voice_event.articulations
      return {} if articulations.empty?

      {"artic" => articulations.map { |articulation| ARTICS.fetch(articulation.name_key) }.join(" ")}
    end

    private

    def carrier?(node)
      carrying = node.kind == :chord || (node.kind == :note && !node.chord_member)
      carrying && (node.grace? || (node.item.link_index.zero? && node.item.segment.elapsed.zero?))
    end
  end

  EventWriter.attribute_sources << ArticAttributes
end
