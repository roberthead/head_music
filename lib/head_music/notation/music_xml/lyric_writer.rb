# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes the <lyric> children of a note.
  #
  # One instance serves a whole document so the walk back to the previous sung
  # note — which decides whether a syllable begins, continues, or ends a word —
  # is memoized per voice and verse.
  class LyricWriter
    include HeadMusic::Notation::XmlText

    # <lyric> is the last child of <note>. Sung text rides only the lead note
    # of a chord and only the attack of a tied chain (a tie_stop component is a
    # continuation, sung once at the start). A melisma's line is an <extend>:
    # start on its syllable, then continue on each held note and stop on the
    # last. A hyphenated syllable's held notes write nothing, as engravers
    # draw hyphens there, and a reader holds them again from the hyphen.
    def lines(voice_event, component, chord:)
      return [] if chord || voice_event.rest? || component.tie_stop

      verses = (voice_event.syllables.keys + voice_event.extended_verses).sort
      verses.flat_map do |verse|
        syllable = voice_event.syllables[verse]
        syllable ? sung_lines(voice_event, syllable) : held_lines(voice_event, verse)
      end
    end

    private

    def sung_lines(voice_event, syllable)
      extend = !syllable.hyphen_after? && voice_event.melisma_continues_after?(syllable.verse)
      [
        %(#{INDENT * 4}<lyric number="#{syllable.verse}">),
        "#{INDENT * 5}<syllabic>#{syllabic(voice_event, syllable)}</syllabic>",
        "#{INDENT * 5}<text>#{escape(syllable.text)}</text>",
        *(extend ? [%(#{INDENT * 5}<extend type="start"/>)] : []),
        "#{INDENT * 4}</lyric>"
      ]
    end

    def held_lines(voice_event, verse)
      return [] if opening_syllable(voice_event, verse).hyphen_after?

      type = voice_event.melisma_continues_after?(verse) ? "continue" : "stop"
      [%(#{INDENT * 4}<lyric number="#{verse}">), %(#{INDENT * 5}<extend type="#{type}"/>), "#{INDENT * 4}</lyric>"]
    end

    # The syllable a held note's melisma began on, through the held notes
    # before it.
    def opening_syllable(voice_event, verse)
      voice_event = voice_event.voice.voice_event_preceding(voice_event.position) while voice_event.extends_syllable?(verse)
      voice_event.syllable(verse)
    end

    # Derives MusicXML's single/begin/middle/end from our stored hyphen_after
    # booleans: this syllable's, and the previous sung note's for the same verse.
    def syllabic(voice_event, syllable)
      from_previous = previous_syllable(voice_event, syllable.verse)&.hyphen_after?
      if from_previous
        syllable.hyphen_after? ? "middle" : "end"
      else
        syllable.hyphen_after? ? "begin" : "single"
      end
    end

    # The syllable on the nearest earlier voice event in the same voice carrying
    # text for this verse. Voice events are position-sorted, and held and unsung
    # notes are skipped because only sung voice events are collected. Array#index compares
    # with ==, which on VoiceEvent is position-only, but a voice holds at most
    # one voice event per position (VoiceEvents#place), so that still
    # locates this exact voice event.
    def previous_syllable(voice_event, verse)
      @sung_voice_events ||= {}
      sung = @sung_voice_events[[voice_event.voice, verse]] ||=
        voice_event.voice.voice_events.select { |candidate| candidate.syllable(verse) }
      index = sung.index(voice_event)
      return nil if index.nil? || index.zero?

      sung[index - 1].syllable(verse)
    end
  end
end
