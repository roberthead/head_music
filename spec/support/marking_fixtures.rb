# Flows carrying articulations, ornaments, and dynamics, shared by the format
# round-trip specs so every format is held to one standard.
module MarkingFixtures
  module_function

  # One voice with a staccato run, a trill, an sfz, an fp, a level under a
  # held note, and several level changes. No accent shares a position with a
  # level, since kern's **dynam spine holds one value per row.
  def marked_melody
    flow = HeadMusic::Content::Flow.new(name: "Marked Melody", key_signature: "C major", meter: "4/4")
    voice = flow.add_voice(role: "melody")
    %w[C5 D5 E5 F5].each_with_index { |pitch, index| voice.place("1:#{index + 1}", :quarter, pitch).articulate(:staccato) }
    voice.place("2:1", :half, "G5").embellish(:trill)
    voice.place("2:3", :half, "A5").note_dynamic = :sfz
    voice.place("3:1", :whole, "G5")
    voice.place("4:1", :quarter, "E5").articulate(:tenuto)
    voice.place("4:2", :dotted_half, "F5").note_dynamic = :fp
    voice.place("5:1", :half, "E5").embellish(:mordent).articulate(:accent)
    voice.place("5:3", :quarter, "D5").embellish(:inverted_mordent).articulate(:staccatissimo)
    voice.place("5:4", :quarter, "C5").embellish(:turn).articulate(:marcato)
    voice.place("6:1", :half, "C5")
    voice.place("6:3", :half)
    voice.place_dynamic("1:1", :p)
    voice.place_dynamic("3:3", :mf)
    voice.place_dynamic("5:1", :f)
    voice.place_dynamic("6:3", :pp)
    flow
  end

  # A grand-staff piano whose dynamics are the part's, with one of the right
  # hand's own, and one part dynamic in the middle of a held note.
  def grand_staff_piano_with_dynamics
    flow = LilyPondFixtures.cross_staff_piano
    piano = flow.parts.first
    piano.place_dynamic("1:1", :p)
    piano.place_dynamic("2:3", :f)
    piano.place_dynamic("4:1", :mp)
    piano.voices.first.place_dynamic("3:1", :mf)
    flow
  end
end

module MarkingExpectations
  # Every note event keeps its markings, and every voice has the same dynamic
  # in force at every note event, whichever events put it there.
  def expect_same_markings(original, round_tripped)
    expect(marking_summary(round_tripped)).to eq marking_summary(original)
  end

  def marking_summary(flow)
    flow.voices.map do |voice|
      voice.note_events.map do |note_event|
        [
          note_event.position.to_s,
          note_event.articulations.map(&:name_key),
          note_event.ornaments.map(&:name_key),
          note_event.note_dynamic&.name_key,
          voice.dynamic_at(note_event.position)&.name_key
        ]
      end
    end
  end
end

RSpec.configure { |config| config.include MarkingExpectations }
