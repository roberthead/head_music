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
  # reads back as one rest per link, so it carries both on its first.
  class SpineTokens
    Event = Data.define(:offset, :link, :pitches, :tie, :syllables, :marks, :opens, :closes) do
      def initialize(opens: "", closes: "", **fields)
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
        return "#{opens}#{recip}r#{closes}" if rest?

        notes = pitches.sort.map { |pitch| "#{TIE_OPENING[tie]}#{recip}#{PitchWriter.token(pitch)}#{marks}#{TIE_CLOSING[tie]}" }
        notes[0] = "#{opens}#{notes[0]}#{closes}"
        notes.join(" ")
      end
    end

    TIE_OPENING = {nil => "", :start => "[", :middle => "", :end => ""}.freeze
    TIE_CLOSING = {nil => "", :start => "", :middle => "_", :end => "]"}.freeze

    def self.rests(from, to)
      return [] unless to > from

      offset = from
      HeadMusic::Notation::DottedDuration.rhythmic_value_for(to - from).tied_chain.map do |link|
        Event.new(offset: offset, link: link, pitches: nil, tie: nil, syllables: {}, marks: "").tap { offset += DurationWriter.fraction(link) }
      end
    end

    attr_reader :voice

    def initialize(voice)
      @voice = voice
    end

    # The voice's own events by bar number, before any padding.
    def placed
      @placed ||= voice.voice_events.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |voice_event, events|
        links = voice_event_links(voice_event)
        links.each_with_index do |(bar_number, link, offset), index|
          events[bar_number] << event_for(voice_event, link, offset, tie_for(index, links.length), index, links.length)
        end
      end
    end

    # Where the voice stops, as [bar number, offset in that bar].
    def finish
      bar_number = placed.keys.max
      bar_number && [bar_number, placed[bar_number].last.finish]
    end

    # Every bar of +bar_lengths+ filled from its start to its length.
    def by_bar(bar_lengths)
      bar_lengths.to_h { |bar_number, length| [bar_number, filled(placed.fetch(bar_number, []), length)] }
    end

    private

    def voice_event_links(voice_event)
      HeadMusic::Notation::BarSplitter.segments_of(voice_event).flat_map do |segment|
        offset = segment_offset(segment)
        segment.rhythmic_value!(RenderError).tied_chain.map do |link|
          [segment.bar_number, link, offset].tap { offset += DurationWriter.fraction(link) }
        end
      end
    end

    def event_for(voice_event, link, offset, tie, index, count)
      Event.new(
        offset: offset, link: link,
        pitches: voice_event.rest? ? nil : voice_event.pitches,
        tie: voice_event.rest? ? nil : tie,
        syllables: index.zero? ? voice_event.syllables : {},
        marks: index.zero? ? MarkCodes.marks(voice_event) : "",
        opens: index.zero? ? span_marks.opens_at(voice_event.position) : "",
        closes: closing_link?(voice_event, index, count) ? span_marks.closes_at(voice_event.position) : ""
      )
    end

    def closing_link?(voice_event, index, count)
      voice_event.rest? ? index.zero? : index == count - 1
    end

    def span_marks
      @span_marks ||= SpanMarks.new(voice)
    end

    def tie_for(index, count)
      return if count == 1
      return :start if index.zero?

      (index == count - 1) ? :end : :middle
    end

    def segment_offset(segment)
      return 0 unless segment.voice_event.position.bar_number == segment.bar_number

      HeadMusic::Notation::BarSplitter.offset_in_bar(segment.voice_event.position)
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
