# Flows carrying tuplets and grace notes, shared by the format round-trip
# specs. Each is built with Voice#place at the voice's next position, since
# the ABC reader cannot read these until it learns tuplets.
module TupletFixtures
  module_function

  def value(name, tuplet = nil)
    HeadMusic::Rudiment::RhythmicValue.get(name, tuplet: tuplet)
  end

  def flow(name, meter: "4/4")
    HeadMusic::Content::Flow.new(name: name, key_signature: "C major", meter: meter)
  end

  # Places each [value, sounds] in turn and answers the voice. A nil sound
  # is a rest.
  def fill(voice, items)
    items.each { |rhythmic_value, sounds| voice.place(voice.next_position, rhythmic_value, sounds) }
    voice
  end

  # Groups the voice events from one index through another.
  def group(voice, first, last, unit: nil)
    events = voice.voice_events
    voice.group_tuplet(from: events[first].position, to: events[last].next_position, unit: unit)
  end

  def run(ratio, unit, pitches)
    pitches.map { |pitch| [value(unit, ratio), pitch] }
  end

  # Triplet eighths twice, then triplet quarters over a half.
  def triplets
    flow("Triplets").tap do |tupleted|
      voice = fill(tupleted.add_voice, run("3:2", :eighth, %w[C4 D4 E4 F4 G4 A4]) + run("3:2", :quarter, %w[B4 C5 D5]) + [[:whole, "C5"]])
      group(voice, 0, 2)
      group(voice, 3, 5)
      group(voice, 6, 8)
    end
  end

  def sextuplet
    flow("Sextuplet").tap do |tupleted|
      voice = fill(tupleted.add_voice, run("6:4", :sixteenth, %w[C4 D4 E4 F4 G4 A4]) + [["dotted half", "G4"], [:whole, "C4"]])
      group(voice, 0, 5)
    end
  end

  def quintuplet
    flow("Quintuplet").tap do |tupleted|
      voice = fill(tupleted.add_voice, run("5:4", :sixteenth, %w[C4 D4 E4 F4 G4]) + [["dotted half", "E4"], [:whole, "C4"]])
      group(voice, 0, 4)
    end
  end

  # Its onsets round to the subtick grid from the group's start.
  def septuplet
    flow("Septuplet").tap do |tupleted|
      voice = fill(tupleted.add_voice, run("7:4", :sixteenth, %w[C4 D4 E4 F4 G4 A4 B4]) + [["dotted half", "C5"], [:whole, "C4"]])
      group(voice, 0, 6)
    end
  end

  # A quarter and an eighth under 3:2, then a rest and a chord.
  def mixed_value_tuplet
    flow("Mixed Values").tap do |tupleted|
      voice = fill(tupleted.add_voice, [
        [value(:quarter, "3:2"), "C4"], [value(:eighth, "3:2"), "D4"],
        [value(:eighth, "3:2"), nil], [value(:quarter, "3:2"), %w[E4 G4]],
        [:half, "F4"], [:whole, "E4"]
      ])
      group(voice, 0, 1)
      group(voice, 2, 3)
    end
  end

  # Two eighths in the time of three, as a 6/8 piece writes them.
  def duplet_in_six_eight
    flow("Duplet", meter: "6/8").tap do |tupleted|
      voice = fill(tupleted.add_voice, run("2:3", :eighth, %w[C4 E4]) + [["dotted quarter", "G4"], ["dotted half", "C5"]])
      group(voice, 0, 1)
    end
  end

  # Triplet eighths with no group, which a writer brackets by threes.
  def ungrouped_tuplet_run
    flow("Ungrouped").tap do |tupleted|
      fill(tupleted.add_voice, run("3:2", :eighth, %w[C4 D4 E4 F4 G4 A4]) + [[:half, "G4"], [:whole, "C4"]])
    end
  end

  # A group ending on the first link of a chain whose later link is plain.
  def triplet_tied_out
    flow("Tied Out").tap do |tupleted|
      voice = fill(tupleted.add_voice, run("3:2", :eighth, %w[C4 D4]) + [[value("triplet eighth tied to quarter"), "E4"], [:half, "F4"], [:whole, "C4"]])
      voice.group_tuplet(from: "1:1", to: "1:2")
    end
  end

  # Triplet quarters from beat 4, the middle one split at the barline.
  def tuplet_crossing_barline
    flow("Crossing").tap do |tupleted|
      voice = fill(tupleted.add_voice, [["dotted half", "C4"], *run("3:2", :quarter, %w[D4 E4 F4]), ["dotted half", "G4"]])
      group(voice, 1, 3)
    end
  end

  # Septuplet eighths from beat 4, the fourth split at the exact barline
  # though its position is rounded.
  def septuplet_crossing_barline
    flow("Septuplet Crossing").tap do |tupleted|
      voice = fill(tupleted.add_voice, [["dotted half", "C4"], *run("7:4", :eighth, %w[D4 E4 F4 G4 A4 B4 C5]), ["dotted half", "D5"]])
      group(voice, 1, 7)
    end
  end

  # Different ratios in the two hands of a piano.
  def tuplets_in_two_voices
    flow("Two Voices").tap do |tupleted|
      right_hand, left_hand = piano_hands(tupleted)
      fill(right_hand, run("3:2", :eighth, %w[E5 F5 G5]) + run("5:4", :sixteenth, %w[A5 G5 F5 E5 D5]) + [[:half, "C5"], [:whole, "E5"]])
      group(right_hand, 0, 2)
      group(right_hand, 3, 7)
      fill(left_hand, [[:half, "C3"], *run("3:2", :quarter, %w[G2 A2 B2]), [:whole, "C3"]])
      group(left_hand, 1, 3)
    end
  end

  # A slashed grace note before a downbeat, a pair whose second is tied into
  # its main note under a slur from the first, a grace chord, and a grace
  # note with a staccato.
  def grace_notes_before_downbeat
    flow("Grace Notes").tap do |graced|
      voice = fill(graced.add_voice, [[:quarter, "C4"], [:quarter, "E4"], [:quarter, "G4"], [:quarter, "F4"], [:whole, "E4"], [:whole, "C4"]])
      events = voice.voice_events
      events[4].add_grace_note("F4", :eighth, slashed: true)
      events[5].add_grace_note("D4", :sixteenth).add_grace_note("C4", :sixteenth, tied: true)
      voice.add_span(:slur, from: "3:1", to: "3:1", from_grace: true)
      events[2].add_grace_note(%w[A4 C5], :sixteenth)
      events[3].add_grace_note("G4", :sixteenth, articulations: [:staccato])
    end
  end

  # Grace notes in a pickup bar, and before the first downbeat.
  def grace_notes_in_pickup
    flow("Graced Pickup").tap do |graced|
      voice = graced.add_voice
      voice.place("0:1", :half)
      fill(voice, [[:quarter, "G3"], [:quarter, "B3"], [:whole, "C4"]])
      events = voice.voice_events
      events[1].add_grace_note("A3", :eighth)
      events[3].add_grace_note("B3", :sixteenth, slashed: true)
    end
  end

  def piano_hands(flow, from: 1)
    staff_system = HeadMusic::Content::StaffSystem.grand_staff
    piano = flow.add_part(instrument: "piano", staff_system: staff_system)
    right_hand = piano.add_voice(role: "right hand")
    left_hand = piano.add_voice(role: "left hand")
    left_hand.cross_to(staff_system.staves.last, from: from)
    [right_hand, left_hand]
  end

  def all
    %i[
      triplets sextuplet quintuplet septuplet mixed_value_tuplet duplet_in_six_eight
      ungrouped_tuplet_run triplet_tied_out tuplet_crossing_barline septuplet_crossing_barline
      tuplets_in_two_voices grace_notes_before_downbeat grace_notes_in_pickup
    ]
  end

  # The fixtures with a tuplet across a barline, which ABC cannot write.
  def crossing_barline
    %i[tuplet_crossing_barline septuplet_crossing_barline]
  end
end

module TupletExpectations
  # Every group comes back with its ends, ratio, and unit. A format that
  # writes ungrouped runs as groups, or groups as plain runs, passes
  # `bracketed`, comparing the brackets a writer would draw instead.
  def expect_same_tuplets(original, round_tripped, bracketed: false)
    summary = bracketed ? :bracket_summary : :tuplet_summary
    expect(public_send(summary, round_tripped)).to eq public_send(summary, original)
  end

  # Every note event keeps its grace notes, and every slur from them.
  def expect_same_grace_notes(original, round_tripped)
    expect(grace_summary(round_tripped)).to eq grace_summary(original)
  end

  # Per voice, each group as [from, to, ratio, unit].
  def tuplet_summary(flow)
    flow.voices.map do |voice|
      voice.tuplets.map { |group| [group.from.to_s, group.to.to_s, group.ratio.to_s, group.unit.to_s] }
    end
  end

  # Per voice, each bracket a writer draws as [start, end, ratio, unit], its
  # ends as exact "bar+offset" points, so that a group and the ungrouped run
  # a writer brackets alike compare alike.
  def bracket_summary(flow)
    flow.voices.map do |voice|
      HeadMusic::Notation::TupletBrackets.for(voice).map do |bracket|
        last = bracket.last
        finish = [last.onset.first, last.onset.last + last.rhythmic_value.link_fraction]
        [exact_point(*bracket.first.onset), exact_point(*finish), bracket.ratio.to_s, bracket.unit.to_s]
      end
    end
  end

  # Per voice, each note event with grace notes as [position, its grace
  # notes as [sounds, value, slashed, tied, articulations]], then the slurs
  # from grace notes.
  def grace_summary(flow)
    flow.voices.map do |voice|
      graced = voice.note_events.reject { |note_event| note_event.grace_notes.empty? }.map do |note_event|
        [note_event.position.to_s, note_event.grace_notes.map { |grace| grace_datum(grace) }]
      end
      [graced, voice.spans.select(&:from_grace?).map(&:to_s)]
    end
  end

  # Per voice, each voice event as [exact onset, exact length, sounds], for
  # a format such as kern that keeps what sounds rather than how it is
  # written.
  def sounding_summary(flow)
    flow.voices.map do |voice|
      voice.voice_events.map do |voice_event|
        onset = exact_point(voice_event.position.bar_number, HeadMusic::Notation::BarSplitter.onset_in_bar(voice_event))
        [onset, voice_event.rhythmic_duration.fraction, voice_event.sounds.map(&:to_s)]
      end
    end
  end

  def grace_datum(grace_note)
    [grace_note.sounds.map(&:to_s), grace_note.rhythmic_value.to_s, grace_note.slashed?, grace_note.tied?, grace_note.articulations.map(&:name_key)]
  end

  def exact_point(bar_number, offset)
    offset = Rational(offset)
    "#{bar_number}+#{(offset.denominator == 1) ? offset.to_i : offset}"
  end
end

RSpec.configure { |config| config.include TupletExpectations }
