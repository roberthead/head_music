# Flows carrying hairpins, shared by the format round-trip specs. Each puts a
# hairpin's end where a writer must think in document order: on a tied or
# split note's later piece, touching another, across voices, or on the final
# barline.
module HairpinFixtures
  module_function

  def abc(title, body)
    HeadMusic::Notation::ABC.parse("X:1\nT:#{title}\nL:1/4\nM:4/4\nK:C\n#{body}\n")
  end

  # A crescendo ending on the later link of a note tied across a barline.
  def hairpin_ending_on_tied_note
    abc("Ending on a Tie", "C D E F-|F G A B|").tap do |flow|
      flow.voices.first.add_span(:crescendo, from: "1:1", to: "2:1")
    end
  end

  # A crescendo ending where a tied note starts, and a diminuendo starting on
  # its later link.
  def hairpin_starting_on_split_note
    abc("Starting on a Tie", "C D E F-|F G A B|").tap do |flow|
      flow.voices.first.add_span(:crescendo, from: "1:1", to: "1:4")
      flow.voices.first.add_span(:diminuendo, from: "2:1", to: "2:3")
    end
  end

  # A crescendo and a diminuendo touching on the later link of a tied note.
  def touching_hairpins_on_tied_note
    abc("Touching on a Tie", "C D E F-|F G A B|").tap do |flow|
      flow.voices.first.add_span(:crescendo, from: "1:1", to: "2:1")
      flow.voices.first.add_span(:diminuendo, from: "2:1", to: "2:4")
    end
  end

  # Hairpins touching where a whole rest crossing a barline starts, the
  # second ending on its later piece.
  def hairpin_on_split_rest
    flow = HeadMusic::Content::Flow.new(name: "Split Rest", meter: "4/4")
    voice = flow.add_voice
    voice.place("1:1", :half, "C4")
    voice.place("1:3", :whole)
    voice.place("2:3", :half, "D4")
    voice.add_span(:crescendo, from: "1:1", to: "1:3")
    voice.add_span(:diminuendo, from: "1:3", to: "2:1")
    flow
  end

  # The left hand's diminuendo ends in bar 3 before the right hand's
  # crescendo starts, so they never overlap in time. But a part writes the
  # right hand's bar before the left hand's, so in document order the
  # crescendo starts before the diminuendo stops.
  def hairpins_in_two_voices
    flow = LilyPondFixtures.cross_staff_piano
    right_hand, left_hand = flow.voices
    right_hand.add_span(:diminuendo, from: "1:1", to: "2:1")
    left_hand.add_span(:diminuendo, from: "2:1", to: "3:2")
    right_hand.add_span(:crescendo, from: "3:3", to: "4:3")
    flow
  end

  # Both ends inside held notes.
  def hairpin_under_held_note
    abc("Under a Held Note", "C4|D2 E2|").tap do |flow|
      flow.voices.first.add_span(:crescendo, from: "1:2", to: "2:2")
    end
  end

  # The piano's own hairpins, the second ending on the final barline, with a
  # right-hand crescendo touching both.
  def part_hairpin
    flow = LilyPondFixtures.cross_staff_piano
    piano = flow.parts.first
    piano.add_span(:crescendo, from: "1:1", to: "2:3")
    flow.voices.first.add_span(:crescendo, from: "2:3", to: "3:1")
    piano.add_span(:diminuendo, from: "3:1", to: "5:1")
    flow
  end

  # A single voice's part holding the hairpins, the second ending on the
  # final barline.
  def single_voice_part_hairpin
    abc("Part Hairpins", "C D E F|G4|").tap do |flow|
      flow.parts.first.add_span(:crescendo, from: "1:1", to: "1:3")
      flow.parts.first.add_span(:diminuendo, from: "1:3", to: "3:1")
    end
  end

  # A crescendo through the last bar to the final barline.
  def hairpin_to_music_end
    abc("To the End", "C4|D4|").tap do |flow|
      flow.voices.first.add_span(:crescendo, from: "2:1", to: "3:1")
    end
  end

  # A short final bar: a crescendo to where its music ends, and a diminuendo
  # from there to the final barline.
  def hairpins_after_short_final_bar
    abc("Short Final Bar", "C4|C D E|").tap do |flow|
      flow.voices.first.add_span(:crescendo, from: "2:1", to: "2:4")
      flow.voices.first.add_span(:diminuendo, from: "2:4", to: "3:1")
    end
  end

  # A crescendo from under a pickup's leading rest to the first downbeat.
  def hairpin_in_pickup
    flow = HeadMusic::Content::Flow.new(name: "Pickup", meter: "4/4")
    voice = flow.add_voice
    voice.place("0:1", :half)
    voice.place("0:3", :half, "C4")
    voice.place("1:1", :whole, "D4")
    voice.add_span(:crescendo, from: "0:2", to: "1:1")
    flow
  end

  # Two parts, the first with one bar of music under a two-bar second, and a
  # hairpin and a level in the first part's bar of rest.
  def hairpin_in_voice_that_ends_early
    flow = HeadMusic::Content::Flow.new(name: "Ends Early", meter: "4/4")
    early = flow.add_voice(role: "upper")
    early.place("1:1", :whole, "E5")
    late = flow.add_voice(role: "lower")
    late.place("1:1", :whole, "C4")
    late.place("2:1", :whole, "D4")
    early.add_span(:crescendo, from: "1:3", to: "2:2")
    early.place_dynamic("2:3", :f)
    flow
  end

  # A crescendo with a level and an accent inside it.
  def level_inside_hairpin
    abc("Level Inside", "C D E F|G4|").tap do |flow|
      voice = flow.voices.first
      voice.add_span(:crescendo, from: "1:1", to: "2:1")
      voice.place_dynamic("1:3", :mf)
      voice.voice_event_at(flow.position("1:4")).note_dynamic = :sf
    end
  end

  def all
    %i[
      hairpin_ending_on_tied_note hairpin_starting_on_split_note touching_hairpins_on_tied_note
      hairpin_on_split_rest hairpins_in_two_voices hairpin_under_held_note part_hairpin
      single_voice_part_hairpin hairpin_to_music_end hairpins_after_short_final_bar
      hairpin_in_pickup hairpin_in_voice_that_ends_early level_inside_hairpin
    ]
  end
end

module HairpinExpectations
  # Every hairpin comes back with its kind and its ends, owned as before. A
  # format with one line for a part's hairpins names that line's owner as
  # `merged_into`, such as "part" for kern or "voice 0" for ABC; one that
  # cuts a hairpin at the dynamics inside it passes `segmented_by`, which
  # takes an owner and its hairpins and answers the pieces it writes.
  def expect_same_hairpins(original, round_tripped, merged_into: nil, segmented_by: nil)
    expect(hairpin_summary(round_tripped)).to eq hairpin_summary(original, merged_into: merged_into, segmented_by: segmented_by)
  end

  # The kinds of hairpin in force at every position where a hairpin starts
  # or ends in either flow, in each voice, or with `per: :part`, in each
  # part, as a format that moves a voice's hairpins to its part keeps them.
  def expect_same_hairpin_in_force(original, round_tripped, per: :voice)
    positions = (hairpin_ends(original) + hairpin_ends(round_tripped)).uniq
    expect(hairpins_in_force(round_tripped, positions, per)).to eq hairpins_in_force(original, positions, per)
  end

  def hairpin_summary(flow, merged_into: nil, segmented_by: nil)
    flow.parts.each_with_index.flat_map do |part, part_index|
      owners = [["part", part], *part.voices.each_with_index.map { |voice, index| ["voice #{index}", voice] }]
      owners.flat_map do |label, owner|
        hairpins = owner.spans.select(&:hairpin?)
        hairpins = segmented_by.call(owner, hairpins) if segmented_by
        hairpins.map { |span| [part_index, merged_into || label, span.name_key, span.from.to_s, span.to.to_s] }
      end
    end.uniq.sort
  end

  def hairpin_ends(flow)
    flow.parts.flat_map { |part| [part, *part.voices] }.flat_map(&:spans).select(&:hairpin?)
      .flat_map { |span| [span.from.to_s, span.to.to_s] }
  end

  def hairpins_in_force(flow, positions, per)
    groups = (per == :part) ? flow.parts.map(&:voices) : flow.voices.zip
    groups.map do |voices|
      positions.sort.map do |code|
        position = flow.position(code)
        [code, voices.flat_map { |voice| voice.spans_at(position) }.select(&:hairpin?).map(&:name_key).uniq.sort]
      end
    end
  end
end

RSpec.configure { |config| config.include HairpinExpectations }
