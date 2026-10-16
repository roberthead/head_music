# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # One measure's timed elements in document order, each with what its
  # written value takes. At divisions that cannot express a triplet or a
  # 32nd, every <duration> is rounded, and the rounding can carry a measure
  # past its bar while the written values fill it. Such a measure is timed
  # by its written values instead.
  #
  # A <backup> or <forward>, or a hidden note read as one, has no written
  # value, so it moves the written cursor by its <duration> and lands on the
  # nearest written onset. The move is relative, so it carries only its own
  # rounding, not all the measure's.
  class WrittenTiming
    Note = Struct.new(:voice, :value, :event, :reaches)
    Move = Struct.new(:delta, :reaches)

    attr_reader :extent

    def initialize
      @steps = []
    end

    # A note's value is nil when it has no <type>, and a whole-measure rest's
    # is the bar's length.
    def note(voice, value, event, reaches:)
      @steps << Note.new(voice, value, event, reaches)
    end

    def move(delta, reaches:)
      @steps << Move.new(delta, reaches)
    end

    def direction(pending)
      @steps << pending
    end

    # Retimes the measure's events and directions, and answers whether it
    # did, which it does only where every voice's written values fill the bar.
    def retime(bar_length)
      return false unless fills?(bar_length)

      @onsets = [0]
      @extent = nil
      @steps.reduce(0) { |cursor, step| retime_step(step, cursor) }
      true
    end

    private

    def fills?(bar_length)
      notes = @steps.grep(Note)
      return false if notes.any? { |note| note.value.nil? }

      notes.group_by(&:voice).values.all? { |voice_notes| voice_notes.sum(&:value) == bar_length }
    end

    def retime_step(step, cursor)
      case step
      when Note then retime_note(step, cursor)
      when Move then retime_move(step, cursor)
      else
        step.cursor = cursor
        cursor
      end
    end

    def retime_note(note, cursor)
      if note.event
        note.event.cursor = cursor
        note.event.duration = note.value
      end
      finish = cursor + note.value
      @onsets.push(cursor, finish)
      reach(finish) if note.reaches
      finish
    end

    def retime_move(move, cursor)
      target = cursor + move.delta
      target = @onsets.min_by { |onset| (onset - target).abs }
      reach(target) if move.reaches
      target
    end

    def reach(cursor)
      @extent = [@extent, cursor].compact.max
    end
  end
end
