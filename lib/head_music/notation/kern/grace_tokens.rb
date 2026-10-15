# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # The tokens of the grace notes before a note event, one per grace note
  # and a chord of them for several pitches: its value, pitch, articulations,
  # a tie into what follows, and q for a slashed grace note or Q for an
  # unslashed one, as 8ccq, 16dQ, or 16c[Q. A slur from the grace notes
  # opens on the first of them.
  #
  # A last grace note tied to a pitch of its note is tied in, so the note
  # continues the tie rather than starting it.
  class GraceTokens
    def initialize(voice_event, span_marks)
      @voice_event = voice_event
      @span_marks = span_marks
    end

    def tokens
      grace_notes.each_with_index.map do |grace_note, index|
        notes = grace_note.pitches.sort.map { |pitch| note(grace_note, pitch) }
        notes[0] = "#{@span_marks.grace_opens_at(@voice_event.position)}#{notes[0]}" if index.zero?
        notes.join(" ")
      end
    end

    def tied_in?
      last = grace_notes.last
      !last.nil? && last.tied? && (last.pitches.map(&:to_s) - @voice_event.pitches.map(&:to_s)).empty?
    end

    private

    def grace_notes
      @voice_event.rest? ? [] : @voice_event.grace_notes
    end

    def note(grace_note, pitch)
      marks = grace_note.articulations.map { |articulation| MarkCodes::ARTICULATIONS.fetch(articulation.name_key) }.join
      "#{DurationWriter.token(grace_note.rhythmic_value)}#{PitchWriter.token(pitch)}#{marks}" \
        "#{"[" if grace_note.tied?}#{grace_note.slashed? ? "q" : "Q"}"
    end
  end
end
