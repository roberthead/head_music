# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # The slurs a voice has opened ahead of its next note, chord, or rest, and
  # those waiting for the note that closes them.
  #
  # A note's slur marks are :open, :grace_open for a slur that starts on its
  # grace notes, and :close.
  class PendingSlurs
    def initialize(voice)
      @voice = voice
      @opens = 0
      @grace_opens = 0
      @open_slurs = []
    end

    def open
      @opens += 1
    end

    # A slur opened before grace notes starts on the first of them.
    def start_on_graces
      @grace_opens += @opens
      @opens = 0
    end

    # Once the grace notes are dropped, their slurs start on what comes next.
    def start_after_graces
      @opens += @grace_opens
      @grace_opens = 0
    end

    def take
      marks = [:grace_open] * @grace_opens + [:open] * @opens
      @grace_opens = 0
      @opens = 0
      marks
    end

    # Slurs pair by nesting, as ABC reads them.
    def apply(voice_event, slur_marks)
      position = voice_event.position
      slur_marks.each do |mark|
        if mark == :close
          close_at(position)
        else
          @open_slurs << [position, mark == :grace_open]
        end
      end
    end

    private

    # A slur the voice refuses, such as one ending on a rest, is dropped.
    def close_at(position)
      from, from_grace = @open_slurs.pop
      @voice.add_span(:slur, from: from, to: position, from_grace: from_grace) if spans?(from, position, from_grace)
    rescue ArgumentError
      nil
    end

    # A slur from grace notes may end on their own main note.
    def spans?(from, to, from_grace)
      return false unless from

      from < to || (from_grace && from == to)
    end
  end
end
