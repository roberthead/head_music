# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Plans the slurs of a voice as ABC's parentheses, which pair by nesting.
  #
  # ABC has no phrase mark, so a phrase is written as a slur, drawn in to
  # the notes at its ends, since a slur cannot begin or end on a rest. One
  # that would cross a slur, or cover the same notes, is left out: the slurs
  # say more. A note cannot both end one slur and begin the next, so a slur that
  # begins where another ends starts on the note after, or is left out when
  # that leaves it one note long. Two slurs that still cross raise.
  class SlurWriter
    Curve = Struct.new(:kind, :from, :to)

    def initialize(voice)
      @voice = voice
      curves = voice ? plan(voice.spans) : []
      @opens = curves.map { |curve| curve.from.to_s }.tally
      @closes = curves.map { |curve| curve.to.to_s }.tally
    end

    def opens(voice_event)
      "(" * @opens.fetch(voice_event.position.to_s, 0)
    end

    def closes(voice_event)
      ")" * @closes.fetch(voice_event.position.to_s, 0)
    end

    private

    def plan(spans)
      curves = spans.filter_map { |span| curve_for(span) }
      curves = curves.reject { |curve| outdone_phrase?(curve, curves) }
      curves = shorten_touching(curves)
      crossing = curves.combination(2).find { |one, other| crossing?(one, other) }
      raise RenderError, "ABC cannot write slurs that cross, as from #{crossing[0].from} and from #{crossing[1].from}" if crossing

      curves
    end

    def curve_for(span)
      return Curve.new(span.kind, span.from, span.to) unless span.kind == :phrase

      notes = @voice.note_events.select { |note_event| note_event.position.between?(span.from, span.to) }
      Curve.new(:phrase, notes.first.position, notes.last.position) if notes.length > 1
    end

    def outdone_phrase?(curve, curves)
      curve.kind == :phrase && curves.any? do |other|
        other.kind == :slur && (crossing?(curve, other) || (other.from == curve.from && other.to == curve.to))
      end
    end

    def crossing?(one, other)
      first, second = [one, other].sort_by(&:from)
      first.from < second.from && second.from < first.to && first.to < second.to
    end

    def shorten_touching(curves)
      loop do
        touching = curves.find { |curve| curves.any? { |other| other.to == curve.from } }
        return curves unless touching

        later = @voice.note_events.find { |note_event| note_event.position > touching.from }
        if later && later.position < touching.to
          touching.from = later.position
        else
          curves = curves.reject { |curve| curve.equal?(touching) }
        end
      end
    end
  end
end
