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
  #
  # A slur from grace notes opens before them, so it may close on their own
  # main note, and it never touches one ending there.
  class SlurWriter
    Curve = Struct.new(:kind, :from, :to, :grace) do
      def start_key
        [from, grace ? 0 : 1]
      end

      # Every slur closes after its last note.
      def end_key
        [to, 2]
      end

      def crosses?(other)
        first, second = [self, other].sort_by(&:start_key)
        second_start = second.start_key
        first_end = first.end_key
        (first.start_key <=> second_start).negative? && (second_start <=> first_end).negative? &&
          (first_end <=> second.end_key).negative?
      end

      # A phrase gives way to a slur it crosses or that covers the same notes.
      def outdone_by?(other)
        kind == :phrase && other.kind == :slur && (crosses?(other) || [other.from, other.to] == [from, to])
      end
    end

    def initialize(voice)
      @voice = voice
      curves = voice ? plan(voice.spans.select(&:curve?)) : []
      grace_curves, note_curves = curves.partition(&:grace)
      @opens = tally(note_curves.map(&:from))
      @grace_opens = tally(grace_curves.map(&:from))
      @closes = tally(curves.map(&:to))
    end

    def opens(voice_event)
      "(" * @opens[voice_event.position.to_s]
    end

    def grace_opens(voice_event)
      "(" * @grace_opens[voice_event.position.to_s]
    end

    def closes(voice_event)
      ")" * @closes[voice_event.position.to_s]
    end

    private

    def tally(positions)
      Hash.new(0).merge(positions.map(&:to_s).tally)
    end

    def plan(spans)
      curves = spans.filter_map { |span| curve_for(span) }
      curves = shorten_touching(curves.reject { |curve| curves.any? { |other| curve.outdone_by?(other) } })
      crossing = curves.combination(2).find { |one, other| one.crosses?(other) }
      raise RenderError, "ABC cannot write slurs that cross, as from #{crossing[0].from} and from #{crossing[1].from}" if crossing

      curves
    end

    def curve_for(span)
      kind = span.kind
      from = span.from
      to = span.to
      grace = span.from_grace?
      return Curve.new(kind, from, to, grace) unless kind == :phrase

      notes = note_positions.select { |position| position.between?(from, to) }
      Curve.new(:phrase, notes.first, notes.last, grace) if notes.length > (grace ? 0 : 1)
    end

    # A slur that begins where another ends starts on the note after, or is
    # left out when no note follows inside it.
    def shorten_touching(curves)
      ends = curves.map(&:to)
      touching = curves.find { |curve| !curve.grace && ends.include?(curve.from) }
      return curves unless touching

      later = note_positions.find { |position| position > touching.from }
      if later && later < touching.to
        touching.from = later
      else
        curves = curves.reject { |curve| curve.equal?(touching) }
      end
      shorten_touching(curves)
    end

    def note_positions
      @note_positions ||= @voice.note_events.map(&:position)
    end
  end
end
