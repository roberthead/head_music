# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # The LilyPond words for each bar segment of one voice's events.
  #
  # A tied chain within a voice event joins its links with the tie mark, and
  # so does a voice event split at a barline, whose piece before the bar check
  # ends in one; a chain of rests emits consecutive untied rests, and a tied
  # chord repeats the whole chord. Each link carries the voice's levels and
  # hairpin marks that fall in it, and only the first the voice event's own
  # marks, after any hairpin ending there and before any starting.
  # A slur closes on the last link and opens on the first, closing first
  # where they are one word, so one slur can end where the next begins. A
  # rest reads back as one rest per link, so it carries both on its first.
  #
  # Each tuplet bracket opens before its first link and closes after its
  # last, outside the link's marks and tie.
  #
  # A voice event sounding where a fermata begins carries \fermata on the
  # link sounding there, so a reader finds it starting no later.
  class SegmentTokens
    def initialize(voice, segments, timed_marks, fermatas = {})
      @voice = voice
      @segments = segments
      @timed_marks = timed_marks
      @fermatas = fermatas
    end

    def to_h
      segments.to_h { |segment| [segment, token(segment)] }
    end

    # What opens and closes each tuplet bracket, by the [segment, link index]
    # it opens before or closes after. A bracket crossing a barline opens in
    # one bar and closes in the next.
    def tuplet_edges
      @tuplet_edges ||= begin
        brackets = HeadMusic::Notation::TupletBrackets.for(voice, segments, error_class: RenderError)
        opens = brackets.to_h { |bracket| [link_key(bracket.first), "\\tuplet #{bracket.ratio.to_a.join("/")} { "] }
        closes = brackets.to_h { |bracket| [link_key(bracket.last), " }"] }
        {opens: opens, closes: closes}
      end
    end

    private

    attr_reader :voice, :segments, :timed_marks, :fermatas

    def token(segment)
      voice_event = segment.voice_event
      words = link_words(segment)
      words[closes_index(segment, words)] += span_marks.closes_at(voice_event.position) if closes?(segment)
      words[0] += span_marks.opens_at(voice_event.position) if starts?(segment)
      words = tied(segment, words) unless voice_event.rest?
      bracketed(segment, words).join(" ")
    end

    def tied(segment, words)
      words.each_with_index.map { |word, index| (index < words.length - 1 || segment.continues) ? "#{word}~" : word }
    end

    def bracketed(segment, words)
      words.each_with_index.map do |word, index|
        key = [segment, index]
        "#{tuplet_edges[:opens][key]}#{word}#{tuplet_edges[:closes][key]}"
      end
    end

    def link_key(link)
      [link.segment, link.index]
    end

    # A link's offsets are exact and sounding, so marks fall where they
    # sound, though the link is written under its ratio.
    def link_words(segment)
      voice_event = segment.voice_event
      bar_number = segment.bar_number
      from = segment.offset || HeadMusic::Notation::BarSplitter.onset_in_bar(voice_event)
      own = starts?(segment) ? MarkWriter.token(voice_event) : ""
      graces = starts?(segment) ? grace_token(voice_event) : ""
      forced = starts?(segment)
      first = starts?(segment)
      segment.rhythmic_value!(RenderError).tied_chain.map do |link|
        to = from + HeadMusic::Notation::DottedDuration.sounding_fraction(link)
        own += "\\fermata" if fermata_in?(voice_event, bar_number, from, to, first)
        word = graces + timed_marks.around(bar_number, from, to, "#{body(voice_event, forced)}#{DurationWriter.token(link)}", own, factor: link.tuplet_ratio&.factor || 1)
        from = to
        own = graces = ""
        forced = first = false
        word
      end
    end

    # A fermata where the event starts goes on its first link, and one
    # beginning later on the link sounding there.
    def fermata_in?(voice_event, bar_number, from, to, first)
      fermata = fermatas[voice_event]
      return false unless fermata
      return first if fermata.from == voice_event.position

      offset = HeadMusic::Notation::BarSplitter.offset_in_bar(fermata.from)
      fermata.from.bar_number == bar_number && offset >= from && offset < to
    end

    def grace_token(voice_event)
      return "" if voice_event.grace_notes.empty?

      position = voice_event.position
      GraceWriter.token(voice_event, slur_opens: span_marks.grace_opens_at(position), implied_slur: span_marks.implied_grace_slur?(position))
    end

    def body(voice_event, forced)
      return "r" if voice_event.rest?

      voice_event.chord? ? PitchWriter.chord(voice_event.pitches, forced: forced) : PitchWriter.token(voice_event.pitch)
    end

    def closes?(segment)
      segment.voice_event.rest? ? starts?(segment) : !segment.continues
    end

    def closes_index(segment, words)
      segment.voice_event.rest? ? 0 : words.length - 1
    end

    # A rounded onset just before a barline starts in the bar before its
    # position's.
    def starts?(segment)
      segment.elapsed.zero?
    end

    def span_marks
      @span_marks ||= SpanMarks.new(voice)
    end
  end
end
