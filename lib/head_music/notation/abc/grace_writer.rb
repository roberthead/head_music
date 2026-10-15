# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Writes the grace notes before a note as "{...}", or "{/...}" for slashed
  # ones. ABC slashes a whole group, so a change between slashed and
  # unslashed starts a new group. Each grace note is written with its
  # articulations, its length relative to the unit note length, and a tie
  # when it is tied to what follows.
  class GraceWriter
    def initialize(pitch_writer, duration_writer, decoration_writer)
      @pitch_writer = pitch_writer
      @duration_writer = duration_writer
      @decoration_writer = decoration_writer
    end

    def prefix(voice_event)
      voice_event.grace_notes.chunk_while { |grace, following| grace.slashed? == following.slashed? }.map do |graces|
        "{#{"/" if graces.first.slashed?}#{graces.map { |grace| token(voice_event, grace) }.join}}"
      end.join
    end

    private

    def token(voice_event, grace)
      pitches = grace.pitches
      unless pitches.length == grace.sounds.length
        raise RenderError, "ABC cannot write the unpitched grace note before the note at #{voice_event.position}"
      end

      @decoration_writer.decorations(grace.articulations) + notes(pitches) +
        @duration_writer.multiplier_string(grace.rhythmic_value) + (grace.tied? ? "-" : "")
    end

    # Low to high, as a chord is written.
    def notes(pitches)
      tokens = pitches.sort.map { |pitch| @pitch_writer.token(pitch) }
      (tokens.length == 1) ? tokens.first : "[#{tokens.join}]"
    end
  end
end
