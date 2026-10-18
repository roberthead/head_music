module HeadMusic::MIDI
  # Dynamic levels placed in a voice, sorted by position and then ranked as
  # Voice#dynamic_at ranks them: the part's, the voice's, then the level a
  # note dynamic such as fp leaves after its note.
  class LevelMarks
    Mark = Data.define(:position, :rank, :level)

    FOLLOW_THROUGH_RANK = -1
    PART_RANK = 0
    VOICE_RANK = 1
    ACCENT_RANK = 2

    # The levels the model places.
    def self.of(voice)
      new(
        voice.part.dynamic_events.map { |event| Mark.new(event.position, PART_RANK, event.level) } +
        voice.dynamic_events.map { |event| Mark.new(event.position, VOICE_RANK, event.level) } +
        voice.voice_events.filter_map do |voice_event|
          level_after = voice_event.note_dynamic&.level_after
          Mark.new(voice_event.position, ACCENT_RANK, level_after) if level_after
        end
      )
    end

    def initialize(marks)
      @marks = marks.each_with_index.sort_by { |mark, index| [mark.position, mark.rank, index] }.map(&:first).freeze
    end

    def with(marks)
      self.class.new(@marks + marks)
    end

    # The last mark at or before +position+.
    def at(position)
      index = count_through(position)
      @marks[index - 1] if index.positive?
    end

    # The level in force at +position+ before the note there leaves its own.
    def before_accent(position)
      index = count_through(position)
      last = at(position)
      index -= 1 if last&.rank == ACCENT_RANK && last.position == position
      @marks[index - 1].level if index.positive?
    end

    # {voice event => the level in force at it}, read in one sweep.
    def levels(voice_events)
      cursor = ChangeCursor.new(@marks, &:position)
      voice_events.each_with_object({}.compare_by_identity) do |voice_event, levels|
        levels[voice_event] = cursor.at(voice_event.position)&.level
      end
    end

    private

    def count_through(position)
      @marks.bsearch_index { |mark| mark.position > position } || @marks.length
    end
  end
end
