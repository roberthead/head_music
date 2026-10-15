require_relative "xml_reading"
require_relative "duration_writer"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads one <note> element into what the part reader needs of it, walking
  # its children once.
  class NoteReader
    include XmlReading

    UNIT_NAMES_BY_TYPE = DurationWriter::TYPES_BY_UNIT_NAME.invert.freeze
    MAX_DOTS = 3

    Note = Struct.new(
      :element, :grace, :slashed, :chord, :cue, :rest, :measure_rest, :pitch, :unpitched, :duration,
      :voice, :staff, :type, :dots, :ratio, :normal_type, :normal_dots, :ties, :tied, :tuplets, :articulations
    )

    def self.read(element, **where)
      new(element, where).note
    end

    def initialize(element, where)
      @element = element
      @where = where
    end

    def note
      note = Note.new(element: @element, dots: 0, ties: [], tied: [], tuplets: [], articulations: [], voice: "1")
      @element.each_element { |child| read_child(note, child) }
      note
    end

    # The written value its <type>, dots, and <time-modification> give, or
    # nil for a note with no <type>.
    def self.written_value(note, **where)
      return unless note.type

      unit_name = UNIT_NAMES_BY_TYPE.fetch(note.type) do
        raise UnsupportedFeatureError.new(%(The note type "#{note.type}" is not supported), **where)
      end
      raise UnsupportedFeatureError.new("A note with #{note.dots} dots is not supported", **where) if note.dots > MAX_DOTS

      HeadMusic::Rudiment::RhythmicValue.new(unit_name, dots: note.dots, tuplet: note.ratio)
    end

    private

    attr_reader :where

    def read_child(note, child)
      case child.name
      when "grace"
        note.grace = true
        note.slashed = attribute(child, "slash", **where) == "yes"
      when "chord" then note.chord = true
      when "cue" then note.cue = true
      when "rest"
        note.rest = true
        note.measure_rest = attribute(child, "measure", **where) == "yes"
      when "pitch" then note.pitch = PitchReader.pitch(child, **where)
      when "unpitched" then note.unpitched = true
      when "duration" then note.duration = text(child, **where)
      when "tie" then note.ties << attribute(child, "type", **where)
      when "voice" then note.voice = text(child, **where).to_s.then { |label| label.empty? ? "1" : label }
      when "type" then note.type = text(child, **where)
      when "dot" then note.dots += 1
      when "time-modification" then read_time_modification(note, child)
      when "staff" then note.staff = integer(text(child, **where), "<staff>", **where)
      when "notations" then read_notations(note, child)
      end
    end

    def read_time_modification(note, element)
      actual = integer(text(element, "actual-notes", **where), "<actual-notes>", **where)
      normal = integer(text(element, "normal-notes", **where), "<normal-notes>", **where)
      note.ratio = HeadMusic::Rudiment::TupletRatio.get([actual, normal]) if actual && normal && actual != normal
      note.normal_type = text(element, "normal-type", **where)
      note.normal_dots = children(element, "normal-dot").length
    rescue ArgumentError
      raise ParseError.new("Unreadable <time-modification> #{actual}:#{normal}", **where)
    end

    def read_notations(note, element)
      element.each_element do |child|
        case child.name
        when "tied" then note.tied << attribute(child, "type", **where)
        when "tuplet" then note.tuplets << [attribute(child, "type", **where), attribute(child, "number", **where) || "1"]
        when "articulations" then child.each_element { |articulation| note.articulations << articulation.name }
        end
      end
    end
  end
end
