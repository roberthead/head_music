# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # One voice's music as the reader collects it: events at exact times,
  # placed on the voice only once every bar is known.
  #
  # A voice may begin at any bar's downbeat and must then be gap-free
  # (Voice::Continuity), so the stretch from its bar's downbeat to its
  # first event, and any stretch it sat out, is filled with rests, split
  # at the barlines.
  class Layer
    Event = Struct.new(:time, :rhythmic_value, :fraction, :pitches, :syllables)

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
      Event.new(time, token.rhythmic_value, token.fraction, token.pitches, []).tap { |event| @events << event }
    end

    def end_time
      last = events.last
      last && (last.time + last.fraction)
    end

    def place(clock)
      assign_opening_staff(clock.bars.first.number)
      return if events.empty?

      bar = clock.bar_containing(events.first.time)
      @position = voice.flow.position(bar.number, 1, 0)
      @time = bar.start
      events.each { |event| place_event(event, clock) }
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
      placement = voice.place(@position, event.rhythmic_value, event.pitches)
      event.syllables.each do |syllable|
        placement.sing(syllable.text, verse: syllable.verse, hyphen_after: syllable.hyphen_after)
      end
      @position = placement.next_position
      @time = event.time + event.fraction
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
