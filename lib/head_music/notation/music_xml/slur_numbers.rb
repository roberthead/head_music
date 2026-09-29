# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # The <slur> numbers of one part's spans. MusicXML has no phrase mark, so a
  # phrase is a slur too.
  #
  # Readers pair slurs by number in document order, which runs through a bar
  # one voice at a time, so the numbers are given in that order: walking each
  # bar's voices and each note's components as they are written, a stop
  # frees its number and a start takes the lowest free one. A start and a
  # stop on one note are written stop first, so one slur can end where the
  # next begins on the same number. MusicXML numbers slurs from 1 to 16.
  class SlurNumbers
    LIMIT = 16

    def initialize(part, plan)
      @plan = plan
      @starts = Hash.new { |hash, key| hash[key] = [] }
      @stops = Hash.new { |hash, key| hash[key] = [] }
      @in_use = {}
      walk(part)
    end

    def starts_at(voice_event)
      @starts.fetch(key(voice_event), [])
    end

    def stops_at(voice_event)
      @stops.fetch(key(voice_event), [])
    end

    # A rest's components are rests of their own, so it stops on its first.
    def self.closing_component?(voice_event, component)
      voice_event.rest? ? !component.tie_stop : !component.tie_start
    end

    private

    attr_reader :plan

    def key(voice_event)
      [voice_event.voice.object_id, voice_event.position.to_s]
    end

    def walk(part)
      spans_by_voice = part.voices.to_h { |voice| [voice, spans_by_end(voice)] }
      plan.bar_numbers.each do |bar_number|
        part.voices.each do |voice|
          plan.segments_by_bar(voice).fetch(bar_number, []).each { |segment| number_segment(segment, spans_by_voice[voice]) }
        end
      end
    end

    def spans_by_end(voice)
      {
        from: voice.spans.group_by { |span| span.from.to_s },
        to: voice.spans.group_by { |span| span.to.to_s }
      }
    end

    def number_segment(segment, spans)
      voice_event = segment.voice_event
      position = voice_event.position.to_s
      plan.components_by_segment[segment].each do |component|
        spans[:to].fetch(position, []).each { |span| stop(span, voice_event) } if self.class.closing_component?(voice_event, component)
        spans[:from].fetch(position, []).each { |span| start(span, voice_event) } unless component.tie_stop
      end
    end

    def stop(span, voice_event)
      number, = @in_use.find { |_number, open_span| open_span.equal?(span) }
      return unless number

      @in_use.delete(number)
      @stops[key(voice_event)] << number
    end

    def start(span, voice_event)
      number = (1..LIMIT).find { |candidate| !@in_use.key?(candidate) }
      raise RenderError, "MusicXML cannot hold more than #{LIMIT} slurs open at once in a part, at #{span.from}" unless number

      @in_use[number] = span
      @starts[key(voice_event)] << number
    end
  end
end
