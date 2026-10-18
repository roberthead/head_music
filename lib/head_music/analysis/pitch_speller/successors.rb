class HeadMusic::Analysis::PitchSpeller
  # The key numbers each note moves to in its voice: those of the notes at the
  # voice's next onset, or a grace note's main notes. Notes given without
  # voices are one voice where none overlaps another.
  class Successors
    def initialize(notes)
      @notes = notes
      @following = {}
      voices.each_value { |positions| follow(positions) }
    end

    def [](position)
      @following[position]
    end

    # 1 or -1 where the note moves by a semitone to a note that follows it.
    def semitone_step(position)
      number = @notes[position].number
      self[position]&.map { |following| following - number }&.find { |difference| difference.abs == 1 }
    end

    private

    def follow(positions)
      chords = positions.sort_by { |position| [@notes[position].onset, position] }
        .chunk_while { |a, b| @notes[a].onset == @notes[b].onset }.to_a
      chords.each_cons(2) { |chord, after| lead(chord, after) }
      chords.each { |chord| lead_grace_notes_to_main_notes(chord) }
    end

    # A grace note has no duration, at its main note's onset.
    def lead_grace_notes_to_main_notes(chord)
      grace_notes, main_notes = chord.partition { |position| @notes[position].duration.zero? }
      lead(grace_notes, main_notes) unless main_notes.empty?
    end

    def lead(positions, targets)
      numbers = targets.map { |position| @notes[position].number }
      positions.each { |position| @following[position] = numbers }
    end

    def voices
      voiced = @notes.each_index.reject { |position| @notes[position].voice.nil? }
      return {nil => @notes.each_index.to_a} if voiced.empty? && !overlapping?

      voiced.group_by { |position| @notes[position].voice }
    end

    def overlapping?
      finish = nil
      @notes.sort_by(&:onset).any? do |note|
        overlaps = finish && note.onset < finish
        finish = [finish, note.onset + note.duration].compact.max
        overlaps
      end
    end
  end
end
