# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # One voice's music as the reader collects it: events at exact times,
  # placed on the voice only once every bar is known.
  #
  # Every voice spans the whole flow, as a spine does, so a voice a split
  # starts late or a join ends early is filled with rests from the flow's
  # first bar to its end, and across any stretch it sat out, split at the
  # barlines. That is also how the writer lays each voice out, so a flow
  # read back from what it wrote is the flow it was.
  #
  # Slur and phrase marks pair up once every event is placed: each close
  # ends the latest open of its kind and elision level. A note's closes come
  # before its opens, so one slur can end where the next begins. A mark
  # left unpaired, or a span its voice refuses, such as a slur ending on a
  # rest, is dropped.
  class Layer
    Event = Struct.new(
      :time, :rhythmic_value, :fraction, :pitches, :syllables, :articulations, :ornaments, :note_dynamic, :span_marks
    )
    SPAN_KINDS = {"(" => :slur, ")" => :slur, "{" => :phrase, "}" => :phrase}.freeze
    CLOSES = %w[) }].freeze

    attr_reader :voice, :events
    # The staff the layer is written on now, which can change mid-spine.
    attr_accessor :staff

    def initialize(voice, staff)
      @voice = voice
      @staff = staff
      @opening_staff = staff
      @events = []
    end

    def add(time, token)
      Event.new(
        time, token.rhythmic_value, token.fraction, token.pitches, [],
        token.articulations, token.ornaments, token.note_dynamic, token.span_marks
      ).tap { |event| @events << event }
    end

    def end_time
      last = events.last
      last && (last.time + last.fraction)
    end

    def place(clock, finish_time)
      first_bar = clock.bars.first
      assign_opening_staff(first_bar.number)
      @position = voice.flow.position(first_bar.number, 1, 0)
      @time = first_bar.start
      @span_marks = []
      events.each { |event| place_event(event, clock) }
      rest_until(finish_time, clock)
      add_spans
    end

    private

    # A voice sits on its part's first staff unless it says otherwise, and
    # it says so from the flow's first bar, pickup included.
    def assign_opening_staff(first_bar)
      return if @opening_staff.equal?(voice.part.staff_system_at(first_bar).first_staff)

      voice.assign_staff(first_bar, @opening_staff)
    end

    def place_event(event, clock)
      rest_until(event.time, clock)
      voice_event = voice.place(@position, event.rhythmic_value, event.pitches)
      mark(voice_event, event) unless voice_event.rest?
      @span_marks << [voice_event.position, event.span_marks] if event.span_marks.any?
      @position = voice_event.next_position
      @time = event.time + event.fraction
    end

    def mark(voice_event, event)
      event.syllables.each do |syllable|
        voice_event.sing(syllable.text, verse: syllable.verse, hyphen_after: syllable.hyphen_after)
      end
      voice_event.articulate(*event.articulations).embellish(*event.ornaments)
      voice_event.note_dynamic = event.note_dynamic
    end

    def add_spans
      open = Hash.new { |hash, key| hash[key] = [] }
      @span_marks.each do |position, marks|
        closes, opens = marks.partition { |mark| CLOSES.include?(mark[-1]) }
        closes.each { |mark| close_span(open[span_key(mark)].pop, position, mark) }
        opens.each { |mark| open[span_key(mark)] << position }
      end
    end

    def close_span(from, to, mark)
      voice.add_span(SPAN_KINDS.fetch(mark[-1]), from: from, to: to) if from && from < to
    rescue ArgumentError
      nil
    end

    def span_key(mark)
      [SPAN_KINDS.fetch(mark[-1]), mark.length - 1]
    end

    def rest_until(time, clock)
      while @time < time
        segment_end = [clock.next_bar_start(@time), time].compact.min
        rest = voice.place(@position, HeadMusic::Notation::DottedDuration.rhythmic_value_for(segment_end - @time))
        @position = rest.next_position
        @time = segment_end
      end
    end
  end
end
