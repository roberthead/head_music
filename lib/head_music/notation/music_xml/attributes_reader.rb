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
    # The transpositions by staff number, nil for one that applies to every
    # staff.
    Attributes = Struct.new(:divisions, :key, :meter, :measure_repeat, :staves, :part_symbol, :clefs, :transpositions)

    def self.read(element, **where)
      new(element, where).attributes
    end

    def initialize(element, where)
      @element = element
      @where = where
    end

    def attributes
      Attributes.new(clefs: {}, transpositions: {}).tap do |attributes|
        @element.each_element do |child|
          case child.name
          when "divisions" then attributes.divisions = divisions(child)
          when "key" then attributes.key ||= key(child)
          when "time" then attributes.meter ||= meter(child)
          when "measure-style" then attributes.measure_repeat ||= !first_child(child, "measure-repeat").nil?
          when "staves" then attributes.staves = staves(child)
          when "part-symbol" then attributes.part_symbol = text(child, **where)
          when "transpose" then attributes.transpositions[integer(attribute(child, "number", **where), "transpose number", **where)] = transposition(child)
          when "clef" then attributes.clefs[(integer(attribute(child, "number", **where), "clef number", **where) || 1)] = ClefReader.clef(child, **where)
          end
        end
      end
    end

    private

    attr_reader :where

    def divisions(element)
      value = rational(text(element, **where), "<divisions>", **where)
      raise ParseError.new("<divisions> must be positive", **where) unless value&.positive?

      value
    end

    def transposition(element)
      diatonic, chromatic, octaves = %w[diatonic chromatic octave-change].map do |name|
        integer(text(element, name, **where), "<#{name}>", **where).to_i
      end
      ConcertTransposition::Step.new(diatonic, chromatic, octaves)
    end

    def staves(element)
      value = integer(text(element, **where), "<staves>", **where)
      raise ParseError.new("<staves> must be positive", **where) unless value&.positive?

      value
    end

    # [fifths, mode], the mode nil where none is written.
    def key(element)
      fifths = text(element, "fifths", **where)
      return if fifths.nil? || attribute(element, "number", **where)

      [integer(fifths, "<fifths>", **where), text(element, "mode", **where)]
    end

    # A meter of added beats, such as 3+2/8, would read as its first number
    # alone, so it raises instead, as does one such as 3/3, whose beat type
    # names no note value. A <time> with neither number, as <senza-misura/>,
    # states no meter.
    def meter(element)
      return unless first_child(element, "beats") || first_child(element, "beat-type")

      beats = text(element, "beats", **where)
      beat_type = text(element, "beat-type", **where)
      if beats&.include?("+") || children(element, "beats").length > 1
        raise UnsupportedFeatureError.new("Compound meters such as #{beats}/#{beat_type} are not supported", **where)
      end

      top = meter_number(beats, "<beats>")
      bottom = meter_number(beat_type, "<beat-type>")
      raise UnsupportedFeatureError.new("The meter #{top}/#{bottom} is not supported", **where) unless HeadMusic::Rudiment::RhythmicUnit.for_denominator_value(bottom)

      HeadMusic::Rudiment::Meter.get("#{top}/#{bottom}")
    end

    def meter_number(text, label)
      value = integer(text, label, **where)
      raise ParseError.new("#{label} must be positive", **where) unless value&.positive?

      value
    end
  end
end
