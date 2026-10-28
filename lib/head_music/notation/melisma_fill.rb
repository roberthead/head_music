# A module for visual music notation
module HeadMusic::Notation; end

# Where a line ends when a format marks only where it starts, as MEI's
# @con="u", kern's "Lord_", and a bare MusicXML <extend/> do, and after a
# hyphenated syllable, whose held notes can only be its own. The syllable
# holds each following note with nothing in its verse, up to the next sung
# note, a rest, a gap, or a note already holding it.
module HeadMusic::Notation::MelismaFill
  def self.fill(voice_event, verse)
    following = holdable_after(voice_event, verse)
    while following
      following.extend_syllable(verse: verse)
      following = holdable_after(following, verse)
    end
  end

  def self.holdable_after(voice_event, verse)
    following = voice_event.voice.voice_event_at(voice_event.next_position)
    following if following && !following.rest? && !following.syllable(verse) && !following.extends_syllable?(verse)
  end
end
