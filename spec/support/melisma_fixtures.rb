# Flows whose syllables are held over several notes, shared by the format
# round-trip specs. Every melisma here but short_melisma's runs to the next
# sung note or rest, so a format that marks only where a line starts still
# says where each ends.
module MelismaFixtures
  module_function

  # A word-final melisma up to the next syllable, one up to a rest, a
  # hyphenated one ("Glo-" … "-ri-"), and one through a note tied across a
  # barline.
  def melismas
    sung_voice("Melismas", [
      ["1:1", :quarter, "C4", "Lord"], ["1:2", :quarter, "D4", :held], ["1:3", :quarter, "E4", :held],
      ["1:4", :quarter, "F4", "praise"],
      ["2:1", :half, "G4", "Glo-"], ["2:3", :quarter, "A4", :held], ["2:4", :quarter, "G4", "-ri-"],
      ["3:1", :half, "F4", "a"], ["3:3", :quarter, "E4", :held], ["3:4", :quarter, nil],
      ["4:1", :half, "D4", "Lord"], ["4:3", :whole, "F4", :held], ["5:3", :half, "C4", "God"]
    ])
  end

  # Two verses whose melismas fall in different places.
  def two_verse_melismas
    sung_voice("Two Verse Melismas", [
      ["1:1", :quarter, "C4", "Lord", "O"], ["1:2", :quarter, "D4", :held, "sing"], ["1:3", :quarter, "E4", "praise", :held],
      ["1:4", :quarter, "F4", :held, "now"], ["2:1", :whole, "G4", "him", "all"]
    ])
  end

  # A melisma that stops before an unsung note, so a format that marks only
  # where a line starts reads it back held up to the next syllable.
  def short_melisma
    sung_voice("Short Melisma", [
      ["1:1", :quarter, "C4", "Lord"], ["1:2", :quarter, "D4", :held], ["1:3", :quarter, "E4"],
      ["1:4", :quarter, "F4", "praise"]
    ])
  end

  def sung_voice(name, rows)
    flow = HeadMusic::Content::Flow.new(name: name, key_signature: "C major", meter: "4/4")
    voice = flow.add_voice(role: "melody")
    rows.each do |position, rhythmic_value, pitch, *verses|
      voice_event = voice.place(position, rhythmic_value, pitch)
      verses.each.with_index(1) { |lyric, verse| sing(voice_event, lyric, verse) if lyric }
    end
    flow
  end

  def sing(voice_event, lyric, verse)
    return voice_event.extend_syllable(verse: verse) if lyric == :held

    voice_event.sing(lyric.delete_prefix("-").delete_suffix("-"), verse: verse, hyphen_after: lyric.end_with?("-"))
  end
end

module MelismaExpectations
  # Every melisma comes back starting and ending where it did.
  def expect_same_melismas(original, round_tripped)
    expect(melisma_ends(round_tripped)).to eq melisma_ends(original)
  end

  # Each melisma as [voice index, verse, the syllable's position, the last
  # held note's position].
  def melisma_ends(flow)
    flow.voices.each_with_index.flat_map do |voice, voice_index|
      voice.voice_events.flat_map do |voice_event|
        voice_event.syllables.keys.select { |verse| voice_event.melisma_continues_after?(verse) }.map do |verse|
          [voice_index, verse, voice_event.position.to_s, last_held(voice_event, verse).position.to_s]
        end
      end
    end
  end

  def last_held(voice_event, verse)
    voice_event = voice_event.voice.voice_event_at(voice_event.next_position) while voice_event.melisma_continues_after?(verse)
    voice_event
  end
end

RSpec.configure { |config| config.include MelismaExpectations }
