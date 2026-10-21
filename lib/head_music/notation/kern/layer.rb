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
  # rest, is dropped. A slur or phrase opening on a note event's first
  # grace note begins there, and its close may then come on that same note.
  # Tuplet groups, which kern does not write, are inferred
  # then too; see TupletGroups. So are fermata marks, each from the tied
  # link it is written on, which FermataMarks makes the flow's fermatas.
  #
  # Invisible rests after a voice's last visible event, in the bar where its
  # music ends, add nothing, as they hold only time for dynamics after the
  # music. Ones that reach a later bar, or are followed by music, are rests,
  # since that bar is written and the voice cannot hold a gap.
  class Layer
    TOKEN_FIELDS = %i[rhythmic_value fraction pitches articulations ornaments note_dynamic span_marks invisible].freeze
    Event = Struct.new(:time, *TOKEN_FIELDS, :syllables, :graces, :grace_opens, :fermatas) do
      def finish
        time + fraction
      end

      def mark(note_event)
        syllables.each do |syllable|
          note_event.sing(syllable.text, verse: syllable.verse, hyphen_after: syllable.hyphen_after)
        end
        note_event.articulate(*articulations).embellish(*ornaments).add_grace_notes(*graces.map(&:grace_note))
        note_event.note_dynamic = note_dynamic
      end
    end
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

    # Each of an event's fermatas is the time of the tied link that holds it.
    # The graces are VoiceCursor::Grace values, and grace_opens the span
    # marks that open on the first of them.
    def add(time, token, graces = [], grace_opens = [])
      Event.new(
        time: time, **token.to_h.slice(*TOKEN_FIELDS), syllables: [], graces: graces, grace_opens: grace_opens,
        fermatas: token.fermata ? [time] : []
      )
        .tap { |event| @events << event }
    end

    def end_time
      events.last&.finish
    end

    def sounding_end_time(clock)
      sounding_events(clock).last&.finish
    end

    def place(clock, finish_time, fermata_marks)
      first_bar = clock.bars.first
      number = first_bar.number
      assign_opening_staff(number)
      @position = voice.flow.position(number, 1, 0)
      @time = first_bar.start
      @span_marks = []
      sounding_events(clock).each { |event| place_event(event, clock, fermata_marks) }
      rest_until(finish_time, clock) if finish_time
      TupletGroups.apply(voice)
      add_spans
    end

    private

    def sounding_events(clock)
      last_visible = events.rindex { |event| !event.invisible }
      return [] unless last_visible

      music_end = events[last_visible].finish
      barline = clock.bars.map(&:start).find { |start| start >= music_end }
      (barline && end_time > barline) ? events : events[..last_visible]
    end

    # A voice sits on its part's first staff unless it says otherwise, and
    # it says so from the flow's first bar, pickup included.
    def assign_opening_staff(first_bar)
      return if @opening_staff.equal?(voice.part.staff_system_at(first_bar).first_staff)

      voice.assign_staff(first_bar, @opening_staff)
    end

    def place_event(event, clock, fermata_marks)
      rest_until(event.time, clock)
      voice_event = voice.place(@position, event.rhythmic_value, event.pitches)
      rest = voice_event.rest?
      event.mark(voice_event) unless rest
      event.fermatas.each { |time| fermata_marks.add(voice_event, from: position_at(time, event, voice_event, clock)) }
      @span_marks << [voice_event.position, event.span_marks, rest ? [] : event.grace_opens]
      @position = voice_event.next_position
      @time = event.finish
    end

    # Each open is [position, whether it opens on the grace notes there],
    # kept under its mark, where a close finds it under its opening mark.
    def add_spans
      open = Hash.new { |hash, key| hash[key] = [] }
      @span_marks.each do |position, marks, grace_opens|
        grace_opens.each { |mark| open[mark] << [position, true] }
        closes, opens = marks.partition { |mark| CLOSES.include?(mark[-1]) }
        closes.each { |mark| close_span(open[mark.tr(")}", "({")].pop, position, mark) }
        opens.each { |mark| open[mark] << [position, false] }
      end
    end

    def close_span(opening, to, mark)
      from, from_grace = opening
      return unless from && (from_grace ? from <= to : from < to)

      voice.add_span(SPAN_KINDS.fetch(mark[-1]), from: from, to: to, from_grace: from_grace)
    rescue ArgumentError
      nil
    end

    def position_at(time, event, voice_event, clock)
      return voice_event.position if time == event.time

      bar = clock.bar_containing(time)
      HeadMusic::Notation::BarSplitter.position_at(voice.flow, bar.number, time - bar.start)
    end

    def rest_until(time, clock)
      while @time < time
        segment_end = [clock.next_bar_start(@time), time].compact.min
        rest = voice.place(@position, HeadMusic::Notation::DottedDuration.rest_value(segment_end - @time))
        @position = rest.next_position
        @time = segment_end
      end
    end
  end
end
