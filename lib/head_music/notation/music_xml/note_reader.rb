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
    FLAG_ATTRIBUTES = {"grace" => ["slash", :slashed], "rest" => ["measure", :measure_rest]}.freeze

    Note = Struct.new(
      :element, :grace, :slashed, :chord, :cue, :hidden, :rest, :measure_rest, :pitch, :unpitched, :duration,
      :voice, :voice_stated, :staff, :type, :dots, :ratio, :normal_type, :normal_dots, :ties, :tied, :tuplets, :articulations
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
      note.hidden = attribute(@element, "print-object", **where) == "no"
      @element.each_element { |child| read_child(note, child) }
      raise ParseError.new("A <note> has no <pitch>, <unpitched>, or <rest>", **where) unless note.pitch || note.unpitched || note.rest

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
      when "chord", "cue", "unpitched" then note[child.name] = true
      when "grace", "rest" then read_flag(note, child)
      when "pitch" then note.pitch = PitchReader.pitch(child, **where)
      when "duration" then note.duration = text(child, **where)
      when "tie" then note.ties << attribute(child, "type", **where)
      when "voice"
        note.voice = text(child, **where).to_s.then { |label| label.empty? ? "1" : label }
        note.voice_stated = true
      when "type" then note.type = text(child, **where)
      when "dot" then note.dots += 1
      when "time-modification" then read_time_modification(note, child)
      when "staff" then note.staff = integer(text(child, **where), "<staff>", **where)
      when "notations" then read_notations(note, child)
      end
    end

    # A <grace slash="yes"/> is slashed, and a <rest measure="yes"/> fills its measure.
    def read_flag(note, child)
      note[child.name] = true
      attribute_name, field = FLAG_ATTRIBUTES.fetch(child.name)
      note[field] = attribute(child, attribute_name, **where) == "yes"
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
