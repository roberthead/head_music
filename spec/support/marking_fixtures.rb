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

  # One voice with a phrase ending on a rest, a slur nested in it, a slur
  # ending on a note tied across a barline with another slur nested inside
  # it, and a slur starting on a note that crosses a barline. Every format
  # can write these by nesting alone.
  def spanned_melody
    flow = HeadMusic::Notation::ABC.parse("X:1\nT:Spanned Melody\nL:1/4\nM:4/4\nK:C\nC D E F|G A B c-|c d e f-|f g z2|\n")
    voice = flow.voices.first
    voice.add_span(:phrase, from: "1:1", to: "4:3")
    voice.add_span(:slur, from: "1:1", to: "1:3")
    voice.add_span(:slur, from: "2:1", to: "2:4")
    voice.add_span(:slur, from: "2:2", to: "2:3")
    voice.add_span(:slur, from: "3:4", to: "4:2")
    flow
  end

  # Two spans of the given kinds that overlap without nesting.
  def crossing_spans(first_kind = :slur, second_kind = :slur)
    four_quarters.tap do |flow|
      flow.voices.first.add_span(first_kind, from: "1:1", to: "1:3")
      flow.voices.first.add_span(second_kind, from: "1:2", to: "1:4")
    end
  end

  # Two slurs where one ends on the note the next begins on.
  def touching_slurs
    four_quarters.tap do |flow|
      flow.voices.first.add_span(:slur, from: "1:1", to: "1:3")
      flow.voices.first.add_span(:slur, from: "1:3", to: "2:1")
    end
  end

  # Two phrases touching on a whole rest that crosses a barline.
  def phrases_on_split_rest
    flow = HeadMusic::Content::Flow.new(name: "Split Rest", meter: "4/4")
    voice = flow.add_voice
    voice.place("1:1", :half, "C4")
    voice.place("1:3", :whole)
    voice.place("2:3", :half, "D4")
    voice.add_span(:phrase, from: "1:1", to: "1:3")
    voice.add_span(:phrase, from: "1:3", to: "2:3")
    flow
  end

  # The grand-staff piano with a phrase over the right hand and a slur in the
  # left hand from the bass staff up to the treble.
  def spanned_piano
    flow = LilyPondFixtures.cross_staff_piano
    right_hand, left_hand = flow.voices
    right_hand.add_span(:phrase, from: "1:1", to: "4:1")
    left_hand.add_span(:slur, from: "1:1", to: "2:1")
    flow
  end

  def four_quarters
    HeadMusic::Notation::ABC.parse("X:1\nT:Four Quarters\nL:1/4\nM:4/4\nK:C\nC D E F|G4|\n")
  end
end

module MarkingExpectations
  # Every note event keeps its markings, and every voice has the same dynamic
  # in force at every note event, whichever events put it there.
  def expect_same_markings(original, round_tripped)
    expect(marking_summary(round_tripped)).to eq marking_summary(original)
  end

  # Every voice has the same spans, each starting and ending where it did.
  def expect_same_spans(original, round_tripped)
    expect(span_summary(round_tripped)).to eq span_summary(original)
  end

  def span_summary(flow)
    flow.voices.map { |voice| voice.spans.map(&:to_s) }
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
