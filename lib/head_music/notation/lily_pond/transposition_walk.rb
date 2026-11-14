# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Moves one voice stream's written pitches and keys to concert pitch once
  # the whole document is read. \transposition sets a Staff property, so a
  # change in one voice of a staff reaches its other voices from the moment
  # it is made: those arrive as foreign changes, [elapsed, step] pairs in
  # whole notes, and are applied before the voice's own music at that time.
  #
  # A key written just before a \transposition, with nothing timed between,
  # is the transposed instrument's, as LilyPond prints it.
  class TranspositionWalk
    MAX_ALTERATIONS = 7

    # Where a stream's own changes fall in time, for the other voices of
    # its staff.
    def self.changes(events)
      elapsed = 0
      events.flat_map do |event|
        changes = event_changes(event, elapsed)
        elapsed += duration(event)
        changes
      end
    end

    def self.event_changes(event, elapsed)
      case event.kind
      when :transposition then [[elapsed, event.transposition]]
      when :note
        (event.graces.map(&:transposition) + [event.grace_transposition]).compact.map { |step| [elapsed, step] } +
          event.inner_events.filter_map { |inner| [elapsed + inner.elapsed.fraction, inner.event.transposition] if inner.event.kind == :transposition }
      else []
      end
    end
    private_class_method :event_changes

    def self.duration(event)
      return 0 unless event.timed?

      %i[note rest].include?(event.kind) ? event.rhythmic_duration.fraction : event.fraction
    end

    attr_reader :opening

    def initialize(foreign_changes)
      @foreign = foreign_changes.dup
      @concert = HeadMusic::Notation::ConcertTransposition.new(errors: HeadMusic::Notation::LilyPond)
      @step = nil
    end

    def resolve(events)
      @events = []
      @settled = 0
      elapsed = 0
      events.each do |event|
        apply_foreign(elapsed)
        @events << resolved(event)
        next unless event.timed?

        note_opening if event.music?
        @settled = @events.length
        elapsed += self.class.duration(event)
      end
      note_opening
      @events
    end

    private

    # The transposition in force where the music starts.
    def note_opening
      return if @opened

      @opened = true
      @opening = @step
    end

    def apply_foreign(elapsed)
      change(@foreign.shift.last) while @foreign.any? && @foreign.first.first <= elapsed
    end

    def change(step)
      @step = step
      @concert.change(nil, step)
    end

    def resolved(event)
      case event.kind
      when :transposition
        change(event.transposition)
        resettle_keys
        event
      when :key then keyed(event)
      when :note then concert_note(event)
      else event
      end
    end

    def resettle_keys
      (@settled...@events.length).each { |index| @events[index] = keyed(@events[index]) if @events[index].kind == :key }
    end

    def concert_note(event)
      graces = event.graces.map do |grace|
        change(grace.transposition) if grace.transposition
        grace.with(pitches: concert(grace.pitches, event.line))
      end
      change(event.grace_transposition) if event.grace_transposition
      pitches = concert(event.pitches, event.line)
      inner_events = event.inner_events.map { |inner| inner.with(event: resolved_inner(inner.event)) }
      event.with(pitches: pitches, graces: graces, inner_events: inner_events)
    end

    def resolved_inner(event)
      return keyed(event) if event.kind == :key

      change(event.transposition) if event.kind == :transposition
      event
    end

    def concert(pitches, line)
      pitches.map { |pitch| @concert.concert(pitch, nil, line_number: line) }
    end

    def keyed(event)
      event.with(key_signature: concert_key(event.written_key_signature, event.line))
    end

    def concert_key(key_signature, line)
      return key_signature unless @step && !@step.identity?

      tonic = @concert.concert(HeadMusic::Rudiment::Pitch.get("#{key_signature.tonic_spelling}4"), nil, line_number: line)
      key = HeadMusic::Rudiment::KeySignature.new(tonic.spelling, key_signature.scale_type)
      return key if key.num_alterations <= MAX_ALTERATIONS

      raise UnsupportedFeatureError.new(
        "The concert key of #{key_signature.name} under \\transposition, #{key.name}, needs more than seven sharps or flats",
        line_number: line
      )
    end
  end
end
