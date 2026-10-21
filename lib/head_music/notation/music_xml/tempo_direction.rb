require_relative "xml_reading"
require_relative "duration_writer"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # What one <direction>, or one <sound> written straight in a measure, says
  # of the tempo: its words, its <metronome> as a tempo with no text, its
  # <sound tempo> in quarter notes per minute, and its <dashes>, each as
  # [type, number].
  #
  # MusicXML has no slot for tempo text, so words are tempo text only where
  # the direction also has a <metronome> or <sound tempo>, or where they
  # begin with a named tempo. Words beginning with a ramp or "a tempo" word
  # are read as that word instead.
  class TempoDirection
    include XmlReading

    UNIT_NAMES_BY_TYPE = DurationWriter::TYPES_BY_UNIT_NAME.invert.freeze
    NAMED_TEMPO = /\A(?:#{HeadMusic::Rudiment::Tempo::NAMED_TEMPO_DEFAULTS.keys.map { |key| Regexp.escape(key.to_s.tr("_", " ")) }.join("|")})(?![[:alnum:]])/i
    PER_MINUTE = /\A\s*(\d+(?:\.\d+)?)/

    attr_reader :words, :metronome, :sound, :dashes

    def self.read(element, **where)
      new(element, where)
    end

    def initialize(element, where)
      @where = where
      @dashes = []
      words = []
      if element.name == "sound"
        read_sound(element)
      else
        children(element, "direction-type").each { |direction_type| read_type(direction_type, words) }
        sound = first_child(element, "sound")
        read_sound(sound) if sound
      end
      @words = words.join(" ").squeeze(" ").strip
      @words = nil if @words.empty?
    end

    # :ramp, :a_tempo, or nil.
    def word_kind
      HeadMusic::Notation::TempoMarkReading.word(words)
    end

    def tempo_text
      words if words && !word_kind && (metronome || sound || NAMED_TEMPO.match?(words))
    end

    def dashes_of(type)
      dashes.filter_map { |dashes_type, number| number if dashes_type == type }
    end

    private

    attr_reader :where

    def read_type(direction_type, words)
      direction_type.each_element do |child|
        case child.name
        when "words" then words << text(child, **where).to_s
        when "metronome" then @metronome ||= metronome_tempo(child)
        when "dashes" then @dashes << [attribute(child, "type", **where), attribute(child, "number", **where) || "1"]
        end
      end
    end

    def read_sound(element)
      tempo = rational(attribute(element, "tempo", **where), "tempo", **where)
      @sound = tempo if tempo&.positive?
    end

    # A metronome mark equating two beats, as a metric modulation does, names
    # no pace, and one whose per-minute is not a number, as "c. 120" is
    # not, is not read.
    def metronome_tempo(element)
      units = children(element, "beat-unit")
      return unless units.one?

      unit_name = UNIT_NAMES_BY_TYPE[text(units.first, **where)]
      per_minute = PER_MINUTE.match(text(element, "per-minute", **where).to_s)
      return unless unit_name && per_minute && per_minute[1].to_r.positive?

      beat = HeadMusic::Rudiment::RhythmicValue.new(unit_name, dots: children(element, "beat-unit-dot").length)
      HeadMusic::Rudiment::Tempo.new(beat, per_minute[1].to_r)
    end
  end
end
