module HeadMusic::MIDI
  # The lyric text a note event sings on a pass of the performance, or nil.
  # Pass n sings verse n where the flow has one, and verse 1 otherwise. When
  # several voices of a part sing at one onset, the first voice's text wins.
  class LyricEvents
    attr_reader :flow

    def initialize(flow)
      @flow = flow
    end

    def text_for(voice_event, pass)
      verse = verse_for(pass)
      singer = singers_at(voice_event).find { |candidate| candidate.syllable(verse) }
      return unless singer.equal?(voice_event)

      syllable = voice_event.syllable(verse)
      syllable.hyphen_after? ? "#{syllable.text}-" : syllable.text
    end

    private

    def verse_for(pass)
      verses.include?(pass) ? pass : 1
    end

    def verses
      @verses ||= flow.voices.flat_map { |voice| voice.note_events.flat_map { |voice_event| voice_event.syllables.keys } }.uniq
    end

    def singers_at(voice_event)
      onsets_in(voice_event.voice.part).fetch(onset(voice_event), [])
    end

    def onsets_in(part)
      @onsets ||= {}
      @onsets[part] ||= part.voices.flat_map(&:note_events).select(&:sung?).group_by { |voice_event| onset(voice_event) }
    end

    def onset(voice_event)
      HeadMusic::Notation::BarSplitter.exact_start(voice_event)
    end
  end
end
