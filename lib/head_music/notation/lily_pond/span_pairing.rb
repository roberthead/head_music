# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Pairs slur and phrase marks within each voice by kind and name. As in
  # LilyPond, an open while one of the same kind and name is open is
  # ignored, a close with none open is dropped, and so is a span the voice
  # refuses, such as a slur ending on a rest. One opened on a note's first
  # grace note starts from_grace, and may end on that same note.
  class SpanPairing
    def initialize
      @open = Hash.new { |hash, voice| hash[voice] = {} }
    end

    def apply(voice_event, span_marks)
      open = @open[voice_event.voice]
      span_marks.each do |mark|
        key = [mark.kind, mark.id]
        next open[key] ||= [voice_event.position, mark.from_grace] if mark.opening

        from, from_grace = open.delete(key)
        add_span(voice_event, mark.kind, from, from_grace) if from
      end
    end

    private

    def add_span(voice_event, kind, from, from_grace)
      to = voice_event.position
      return if from > to || (from == to && !from_grace)

      voice_event.voice.add_span(kind, from: from, to: to, from_grace: from_grace)
    rescue ArgumentError
      nil
    end
  end
end
