require_relative "xml_reading"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads an <attributes> element: the divisions, and the key and time it
  # states. A <key> for one staff alone is skipped, since the timeline holds
  # one key for every staff. A <multiple-rest> only changes how rests are
  # drawn, so it is skipped, but reading a <measure-repeat> as rests would
  # change the music, so it is noted for the part reader to refuse.
  class AttributesReader
    include XmlReading

    # The clefs by staff number, a nil clef being one the catalog lacks.
    Attributes = Struct.new(:divisions, :key, :meter, :measure_repeat, :staves, :clefs)

    def self.read(element, **where)
      new(element, where).attributes
    end

    def initialize(element, where)
      @element = element
      @where = where
    end

    def attributes
      Attributes.new(clefs: {}).tap do |attributes|
        @element.each_element do |child|
          case child.name
          when "divisions" then attributes.divisions = divisions(child)
          when "key" then attributes.key ||= key(child)
          when "time" then attributes.meter ||= meter(child)
          when "measure-style" then attributes.measure_repeat ||= !first_child(child, "measure-repeat").nil?
          when "staves" then attributes.staves = staves(child)
          when "clef" then attributes.clefs[(integer(attribute(child, "number", **where), "clef number", **where) || 1)] = ClefReader.clef(child, **where)
          end
        end
      end
    end

    private

    attr_reader :where

    def divisions(element)
      value = rational(text(element, **where), "<divisions>", **where)
      raise ParseError.new("<divisions> must be positive", **where) unless value.positive?

      value
    end

    def staves(element)
      value = integer(text(element, **where), "<staves>", **where)
      raise ParseError.new("<staves> must be positive", **where) unless value.positive?

      value
    end

    # [fifths, mode], the mode nil where none is written.
    def key(element)
      fifths = text(element, "fifths", **where)
      return if fifths.nil? || attribute(element, "number", **where)

      [integer(fifths, "<fifths>", **where), text(element, "mode", **where)]
    end

    # A meter of added beats, such as 3+2/8, would read as its first number
    # alone, so it raises instead.
    def meter(element)
      beats = text(element, "beats", **where)
      beat_type = text(element, "beat-type", **where)
      return unless beats && beat_type

      if beats.include?("+") || children(element, "beats").length > 1
        raise UnsupportedFeatureError.new("Compound meters such as #{beats}/#{beat_type} are not supported", **where)
      end

      HeadMusic::Rudiment::Meter.get("#{integer(beats, "<beats>", **where)}/#{integer(beat_type, "<beat-type>", **where)}")
    end
  end
end
