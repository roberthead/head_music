# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # One voice's tokens, bar by bar, each at its offset in the bar as a
  # fraction of a whole note.
  #
  # A voice event that crosses a barline, or whose value is a tied chain, is
  # written as one token per link, and the tie marks run across the whole
  # voice event: [ on the first link, _ between, ] on the last. A kern spine
  # must sound from its first row to its last, so every bar is filled with
  # rests wherever the voice is silent.
  class SpineTokens
    Event = Data.define(:offset, :link, :pitches, :tie, :syllables, :marks) do
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
        return "#{recip}r" if rest?

        pitches.sort.map { |pitch| "#{TIE_OPENING[tie]}#{recip}#{PitchWriter.token(pitch)}#{marks}#{TIE_CLOSING[tie]}" }.join(" ")
      end
    end

    TIE_OPENING = {nil => "", :start => "[", :middle => "", :end => ""}.freeze
    TIE_CLOSING = {nil => "", :start => "", :middle => "_", :end => "]"}.freeze

    ARTICULATION_MARKS = {"staccato" => "'", "staccatissimo" => "`", "accent" => "^", "tenuto" => "~", "marcato" => "^^"}.freeze
    ORNAMENT_MARKS = {"trill" => "T", "mordent" => "M", "inverted_mordent" => "W", "turn" => "S"}.freeze
    # The other note dynamics have no token signifier, so they go in **dynam.
    NOTE_DYNAMIC_MARKS = {"sfz" => "z"}.freeze

    def self.marks(voice_event)
      [
        *voice_event.articulations.map { |articulation| ARTICULATION_MARKS.fetch(articulation.name_key) },
        *voice_event.ornaments.map { |ornament| ORNAMENT_MARKS.fetch(ornament.name_key) },
        NOTE_DYNAMIC_MARKS[voice_event.note_dynamic&.name_key]
      ].join
    end

    FIRST_PIECE_TIE = {nil => :start, :start => :start, :middle => :middle, :end => :middle}.freeze
    LAST_PIECE_TIE = {nil => :end, :start => :middle, :middle => :middle, :end => :end}.freeze

    # Splits every event sounding across one of the +cuts+ there, a note as
    # tied links and a rest as rests. A row has a time in kern only where
    # something attacks, so this is how a dynamic that falls in the middle
    # of a note gets a row of its own.
    def self.cut(events, cuts)
      events.flat_map do |event|
        inside = cuts.select { |cut| cut > event.offset && cut < event.finish }.sort
        inside.empty? ? [event] : pieces(event, inside)
      end
    end

    def self.pieces(event, cuts)
      bounds = [event.offset, *cuts, event.finish]
      links = bounds.each_cons(2).flat_map do |from, to|
        rhythmic_value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(to - from)
        raise RenderError, "cannot split a note at a dynamic into binary note values (a piece of #{to - from} of a whole note)" unless rhythmic_value

        rhythmic_value.tied_chain
      end
      offset = event.offset
      links.each_with_index.map do |link, index|
        piece_tie = event.rest? ? nil : piece_tie(event.tie, index, links.length)
        first = index.zero?
        event.with(offset: offset, link: link, tie: piece_tie, syllables: first ? event.syllables : {}, marks: first ? event.marks : "")
          .tap { offset += DurationWriter.fraction(link) }
      end
    end

    def self.piece_tie(tie, index, count)
      return FIRST_PIECE_TIE[tie] if index.zero?

      (index == count - 1) ? LAST_PIECE_TIE[tie] : :middle
    end

    private_class_method :pieces, :piece_tie

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
          events[bar_number] << event_for(voice_event, link, offset, tie_for(index, links.length), index)
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

    def event_for(voice_event, link, offset, tie, index)
      Event.new(
        offset: offset, link: link,
        pitches: voice_event.rest? ? nil : voice_event.pitches,
        tie: voice_event.rest? ? nil : tie,
        syllables: index.zero? ? voice_event.syllables : {},
        marks: index.zero? ? self.class.marks(voice_event) : ""
      )
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
