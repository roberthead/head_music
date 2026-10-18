class HeadMusic::Content::Voice
  # What a voice's spans sit on: the voice events at their ends, which a
  # span's kind says it needs, and the note that a span covering its last
  # note runs until the end of.
  class SpanAnchors
    def initialize(voice)
      @voice = voice
    end

    def ensure_anchored(span)
      raise ArgumentError, "a voice cannot hold a #{span.name_key}" unless span.span_kind.held_by?(:voice)

      [span.from, span.to].each { |position| ensure_anchor(span, position) }
      ensure_grace_notes(span) if span.from_grace?
    end

    def end_of(span)
      last = span.span_kind.covers_last_note? && @voice.voice_event_at(span.to)
      last ? last.next_position : span.to
    end

    private

    def ensure_anchor(span, position)
      return if span.span_kind.anchors_on?(@voice.voice_event_at(position))

      raise ArgumentError,
        "a #{span.name_key} must start and end on #{span.span_kind.anchor_description} of its voice, but #{position} has none"
    end

    def ensure_grace_notes(span)
      return if @voice.voice_event_at(span.from)&.grace_notes&.any?

      raise ArgumentError, "a #{span.name_key} from grace notes needs a note with grace notes at #{span.from}"
    end
  end
end
