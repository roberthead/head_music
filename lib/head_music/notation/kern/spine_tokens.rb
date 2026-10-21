# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # One voice's tokens, bar by bar, each at its offset in the bar as a
  # fraction of a whole note.
  #
  # A voice event that crosses a barline, or whose value is a tied chain, is
  # written as one token per link, and the tie marks run across the whole
  # voice event: [ on the first link, _ between, ] on the last. A kern spine
  # must sound from its first row to its last, so every bar is filled with
  # rests wherever the voice is silent. Slur and phrase marks open on a
  # voice event's first link and close on its last, once per chord. A rest
  # reads back as one rest per link, so it carries both on its first. A
  # voice event sounding where a timeline fermata begins marks the link
  # sounding there with ;, as every voice does.
  #
  # Offsets are exact, so a rounded tuplet note sits at its exact onset, and
  # each link takes its sounding length.
  #
  # A note event's grace notes go with its first link, as tokens of their
  # own; see GraceTokens.
  #
  # Time written past the music's end, to hold a dynamic there, is filled
  # with invisible rests, which the reader leaves out.
  class SpineTokens
    Event = Data.define(:offset, :link, :pitches, :tie, :syllables, :marks, :opens, :closes, :invisible, :graces, :fermata) do
      def initialize(opens: "", closes: "", invisible: false, graces: [], fermata: false, **fields)
        super
      end

      def fraction
        DurationWriter.fraction(link)
      end

      def finish
        offset + fraction
      end

      def rest?
        pitches.nil?
      end

      def token
        recip = DurationWriter.token(link)
        first, *others = if rest?
          ["#{recip}r#{FERMATA if fermata}#{"yy" if invisible}"]
        else
          pitches.sort.map do |pitch|
            "#{TIE_OPENING[tie]}#{recip}#{PitchWriter.token(pitch)}#{marks}#{FERMATA if fermata}#{TIE_CLOSING[tie]}"
          end
        end
        ["#{opens}#{first}#{closes}", *others].join(" ")
      end
    end

    FERMATA = ";"
    TIE_OPENING = {nil => "", :start => "[", :middle => "", :end => ""}.freeze
    TIE_CLOSING = {nil => "", :start => "", :middle => "_", :end => "]"}.freeze
    # A note a grace note is tied into continues the grace note's tie.
    TIED_IN = {nil => :end, :start => :middle}.freeze

    def self.rests(from, to)
      return [] unless to > from

      offset = from
      HeadMusic::Notation::DottedDuration.rest_value(to - from).tied_chain.map do |link|
        Event.new(offset: offset, link: link, pitches: nil, tie: nil, syllables: {}, marks: "")
          .tap { offset += DurationWriter.fraction(link) }
      end
    end

    attr_reader :voice

    def initialize(voice)
      @voice = voice
    end

    # The voice's own events by bar number, before any padding.
    def placed
      @placed ||= voice.voice_events.flat_map { |voice_event| events_of(voice_event) }
        .group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
    end

    # Where the voice stops, as [bar number, offset in that bar].
    def finish
      bar_number, events = placed.max_by(&:first)
      [bar_number, events.last.finish] if bar_number
    end

    # Every bar of +bar_lengths+ filled from its start to its length, with
    # invisible rests after +music_end+, given as [bar number, offset].
    def by_bar(bar_lengths, music_end)
      end_bar, end_offset = music_end
      bar_lengths.to_h do |bar_number, length|
        events = placed.fetch(bar_number, [])
        next [bar_number, filled(events, length)] unless bar_number == end_bar

        invisible = self.class.rests(end_offset, length).map { |rest| rest.with(invisible: true) }
        [bar_number, filled(events, end_offset) + invisible]
      end
    end

    private

    def voice_event_links(voice_event)
      HeadMusic::Notation::BarSplitter.segments_of(voice_event).flat_map do |segment|
        offset = segment.offset
        segment.rhythmic_value!(RenderError).tied_chain.map do |link|
          [segment.bar_number, link, offset].tap { offset += DurationWriter.fraction(link) }
        end
      end
    end

    # Each link as [its bar number, its event]. The first link carries the
    # voice event's grace notes, syllables, marks, and opens, and its closing
    # link its closes.
    def events_of(voice_event)
      links = voice_event_links(voice_event)
      last = links.length - 1
      rest = voice_event.rest?
      closing = rest ? 0 : last
      fermata_indexes = fermata_links(voice_event, links)
      links.each_with_index.map do |(bar_number, link, offset), index|
        event = Event.new(
          offset: offset, link: link, pitches: (voice_event.pitches unless rest), tie: (tie_for(index, last) unless rest),
          syllables: {}, marks: ""
        )
        event = first_link(event, voice_event) if index.zero?
        event = event.with(fermata: true) if fermata_indexes.include?(index)
        event = event.with(closes: span_marks.closes_at(voice_event.position)) if index == closing
        [bar_number, event]
      end
    end

    # The links sounding where each of the voice event's fermatas begins.
    def fermata_links(voice_event, links)
      fermata_carriers.fetch(voice_event, []).map do |fermata|
        start = [fermata.from.bar_number, HeadMusic::Notation::BarSplitter.offset_in_bar(fermata.from)]
        links.rindex { |bar_number, _link, offset| ([bar_number, offset] <=> start) <= 0 }
      end
    end

    def fermata_carriers
      @fermata_carriers ||= HeadMusic::Notation::FermataMarks.carriers(voice.flow)
    end

    def first_link(event, voice_event)
      graces = GraceTokens.new(voice_event, span_marks)
      tie = event.tie
      event.with(
        tie: graces.tied_in? ? TIED_IN.fetch(tie) : tie, graces: graces.tokens, syllables: voice_event.syllables,
        marks: MarkCodes.marks(voice_event), opens: span_marks.opens_at(voice_event.position)
      )
    end

    def span_marks
      @span_marks ||= SpanMarks.new(voice)
    end

    def tie_for(index, last)
      return if last.zero?
      return :start if index.zero?

      (index == last) ? :end : :middle
    end

    def filled(events, length)
      cursor = 0
      padded = events.flat_map do |event|
        self.class.rests(cursor, event.offset).tap { cursor = event.finish } + [event]
      end
      padded + self.class.rests(cursor, length)
    end
  end
end
