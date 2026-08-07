require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Serializes the <lyric> children of a note.
  #
  # One instance serves a whole document so the walk back to the previous sung
  # note — which decides whether a syllable begins, continues, or ends a word —
  # is memoized per voice and verse.
  class LyricWriter
    include XmlText

    # <lyric> is the last child of <note>. Sung text rides only the lead note
    # of a chord and only the attack of a tied chain (a tie_stop component is a
    # continuation, sung once at the start). Held notes of a melisma carry no
    # syllable and so emit nothing, matching MusicXML's continuation-by-absence.
    def lines(placement, component, chord:)
      return [] if chord || placement.rest? || component.tie_stop

      placement.syllables.keys.sort.flat_map do |verse|
        syllable = placement.syllables[verse]
        [
          %(#{INDENT * 4}<lyric number="#{verse}">),
          "#{INDENT * 5}<syllabic>#{syllabic(placement, syllable)}</syllabic>",
          "#{INDENT * 5}<text>#{escape(syllable.text)}</text>",
          "#{INDENT * 4}</lyric>"
        ]
      end
    end

    private

    # Derives MusicXML's single/begin/middle/end from our stored hyphen_after
    # booleans: this syllable's, and the previous sung note's for the same verse.
    def syllabic(placement, syllable)
      from_previous = previous_syllable(placement, syllable.verse)&.hyphen_after?
      if from_previous
        syllable.hyphen_after? ? "middle" : "end"
      else
        syllable.hyphen_after? ? "begin" : "single"
      end
    end

    # The syllable on the nearest earlier placement in the same voice carrying
    # text for this verse. Placements are position-sorted, and melisma gaps are
    # skipped because only sung placements are collected. Array#index compares
    # with ==, which on Placement is position-only, but a voice holds at most
    # one placement per position (Voice#insert_into_placements), so that still
    # locates this exact placement.
    def previous_syllable(placement, verse)
      @sung_placements ||= {}
      sung = @sung_placements[[placement.voice, verse]] ||=
        placement.voice.placements.select { |candidate| candidate.syllable(verse) }
      index = sung.index(placement)
      return nil if index.nil? || index.zero?

      sung[index - 1].syllable(verse)
    end
  end
end
