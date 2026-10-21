# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # A note or chord whose placing is deferred until we know whether a
  # broken-rhythm mark follows it. The pitches are computed eagerly so
  # bar-line accidental resets cannot corrupt them. `tied_prefix`, when
  # present, is the already-built rhythmic value of everything tied ahead of
  # this note.
  #
  # Its slur marks wait with it, in the order written, since its position
  # is not known until it is placed. So do the ends of any tuplet it begins
  # or ends, and its grace notes.
  class PendingNote < Data.define(:pitches, :length, :scale, :tied_prefix, :beam_break, :decorations, :slur_marks, :ratio, :tuplet_ends, :graces)
    def initialize(pitches:, length:, scale:, tied_prefix: nil, beam_break: nil, decorations: [], slur_marks: [], ratio: nil, tuplet_ends: [], graces: [])
      super
    end

    # The whole tie chain, so that it renders as one sounding note.
    def rhythmic_value(duration_resolver)
      own = duration_resolver.rhythmic_value(length, scale: scale, tuplet: ratio)
      tied_prefix ? tied_prefix.append_tied(own) : own
    end

    def closing_slur
      with(slur_marks: slur_marks + [:close])
    end

    def decorated(more_decorations)
      with(decorations: decorations + more_decorations)
    end

    def scaled(factor)
      with(scale: scale * factor)
    end

    # A tie carries its accidental across the bar line, where the key
    # signature would otherwise respell the note, so the same letters in the
    # same octaves are the same pitches.
    def ties_to?(other_pitches)
      letters_and_registers(pitches) == letters_and_registers(other_pitches)
    end

    # This note becomes the tied prefix of the link tied onto it, keeping its
    # pitches, beam break, and grace notes, and gathering the link's marks.
    def tied_to(link, prefix, fixed_tuplet_ends)
      with(
        length: link.length, scale: link.scale, tied_prefix: prefix, ratio: link.ratio,
        decorations: decorations + link.decorations, slur_marks: slur_marks + link.slur_marks,
        tuplet_ends: fixed_tuplet_ends + link.tuplet_ends
      )
    end

    # Its authored beam break and its grace notes.
    def carry_onto(voice_event)
      voice_event.beam_break_before = beam_break
      voice_event.add_grace_notes(*graces)
    end

    private

    def letters_and_registers(pitch_list)
      pitch_list.map { |pitch| [pitch.letter_name.to_s, pitch.register] }.sort
    end
  end
end
