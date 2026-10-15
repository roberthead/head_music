# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Writes the grace notes before a note event's first link: \acciaccatura
  # or \appoggiatura where a slur from them to the main note goes without
  # saying, and \slashedGrace or \grace otherwise, with any slur from them
  # opened on the first. Consecutive grace notes alike in slash share one
  # command, braced when there are several.
  module GraceWriter
    module_function

    def token(voice_event, slur_opens: "", implied_slur: false)
      grace_notes = voice_event.grace_notes
      words = grace_notes.each_with_index.map do |grace_note, index|
        "#{word(grace_note)}#{slur_opens if index.zero?}#{"~" if grace_note.tied?}"
      end
      runs = grace_notes.each_index.chunk_while { |one, other| grace_notes[one].slashed? == grace_notes[other].slashed? }
      runs.map { |indexes|
        run = words.values_at(*indexes)
        "#{command(grace_notes[indexes.first].slashed?, implied_slur)} #{(run.length == 1) ? run.first : "{ #{run.join(" ")} }"} "
      }.join
    end

    def command(slashed, implied_slur)
      return (slashed ? "\\acciaccatura" : "\\appoggiatura") if implied_slur

      slashed ? "\\slashedGrace" : "\\grace"
    end

    def word(grace_note)
      pitches = grace_note.pitches.sort.map { |pitch| PitchWriter.token(pitch) }
      body = (pitches.length == 1) ? pitches.first : "<#{pitches.join(" ")}>"
      "#{body}#{DurationWriter.token(grace_note.rhythmic_value)}#{MarkWriter.grace_token(grace_note)}"
    end
  end
end
