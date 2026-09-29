# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # The <slur> numbers of one part's spans. MusicXML has no phrase mark, so a
  # phrase is a slur too. Readers pair slurs by number within a part, so each
  # span open at once, in any of the part's voices, takes the lowest number
  # not in use; that is what lets slurs cross. A span that begins where
  # another ends may take its number, since the stop is written first.
  # MusicXML numbers slurs from 1 to 16.
  class SlurNumbers
    LIMIT = 16

    def initialize(part)
      @starts = Hash.new { |hash, key| hash[key] = [] }
      @stops = Hash.new { |hash, key| hash[key] = [] }
      numbered(part.voices).each do |voice, span, number|
        @starts[[voice.object_id, span.from.to_s]] << number
        @stops[[voice.object_id, span.to.to_s]] << number
      end
    end

    def starts_at(voice_event)
      @starts.fetch([voice_event.voice.object_id, voice_event.position.to_s], [])
    end

    def stops_at(voice_event)
      @stops.fetch([voice_event.voice.object_id, voice_event.position.to_s], [])
    end

    private

    def numbered(voices)
      spans = voices.flat_map { |voice| voice.spans.map { |span| [voice, span] } }.sort_by { |_voice, span| span.from }
      spans.each_with_object([]) do |(voice, span), placed|
        in_use = placed.filter_map { |_other_voice, other, number| number if other.to > span.from }
        number = (1..LIMIT).find { |candidate| !in_use.include?(candidate) }
        raise RenderError, "MusicXML cannot hold more than #{LIMIT} slurs open at once in a part, at #{span.from}" unless number

        placed << [voice, span, number]
      end
    end
  end
end
