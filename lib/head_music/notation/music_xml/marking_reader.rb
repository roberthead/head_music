require_relative "mark_reader"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads articulations, ornaments, and note dynamics in <notations>.
  #
  # Markings are read from a note's attack only, combined across its chord
  # tones. An accent dynamic there is the note's own, the first one winning,
  # and a level becomes the voice's dynamic at the note. Grace notes carry
  # their own articulations from the core; breath marks, caesuras,
  # <technical>, and dynamics the gem does not know are skipped.
  class MarkingReader < MarkReader
    LEVELS_BY_ELEMENT = HeadMusic::Rudiment::Dynamic.levels.to_h { |level| [level.name_key, level] }.freeze

    Marked = Struct.new(:voice, :voice_event, :articulations, :ornaments, :accents, :levels) do
      def empty?
        [articulations, ornaments, accents, levels].all?(&:empty?)
      end
    end

    def initialize
      @marked = []
    end

    def note(record)
      return if record.grace? || record.continuation? || record.voice_event.nil? || record.voice.nil?

      marked = read(record)
      @marked << marked unless marked.empty?
    end

    def apply(_flow)
      @marked.each do |marked|
        mark(marked) unless marked.voice_event.rest?
        place_level(marked) if marked.levels.any?
      end
    end

    private

    def read(record)
      groups = XmlReading.children(record.element, "notations").flat_map { |notations| child_elements(notations) }
      Marked.new(
        record.voice, record.voice_event,
        names_in(groups, "articulations").filter_map { |name| MarkingElements.articulation(name) },
        names_in(groups, "ornaments").filter_map { |name| MarkingElements.ornament(name) },
        names_in(groups, "dynamics").filter_map { |name| MarkingElements.dynamic(name) },
        names_in(groups, "dynamics").filter_map { |name| LEVELS_BY_ELEMENT[name] }
      )
    end

    def names_in(groups, group_name)
      groups.select { |group| group.name == group_name }.flat_map { |group| child_elements(group).map(&:name) }
    end

    def child_elements(element)
      result = []
      element.each_element { |child| result << child }
      result
    end

    def mark(marked)
      note_event = marked.voice_event
      note_event.articulate(*marked.articulations)
      note_event.embellish(*marked.ornaments)
      accent = marked.accents.first
      note_event.note_dynamic = accent if accent && note_event.note_dynamic.nil?
    end

    def place_level(marked)
      marked.voice.place_dynamic(marked.voice_event.position, marked.levels.first)
    rescue ArgumentError
      nil
    end
  end
end
