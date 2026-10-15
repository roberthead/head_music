# Flows whose beams, tuplets, and grace notes nest in the ways an MEI layer
# must arrange, beyond what the shared fixtures cover.
module MEILayerFixtures
  module_function

  # Six triplet sixteenths grouped as one bracket from the second eighth of
  # the bar, so each beat's beam cuts across it.
  def beams_across_tuplet
    TupletFixtures.flow("Beams Across").tap do |flow|
      voice = TupletFixtures.fill(flow.add_voice, [[:eighth, "C4"], *TupletFixtures.run("3:2", :sixteenth, %w[D4 E4 F4 G4 A4 B4]), [:eighth, "C5"], [:half, "D5"]])
      TupletFixtures.group(voice, 1, 6)
    end
  end

  # An eighth and three triplet sixteenths under one beam.
  def tuplet_inside_beam
    TupletFixtures.flow("Inside", meter: "2/4").tap do |flow|
      voice = TupletFixtures.fill(flow.add_voice, [[:eighth, "C4"], *TupletFixtures.run("3:2", :sixteenth, %w[D4 E4 F4]), [:quarter, "G4"]])
      TupletFixtures.group(voice, 1, 3)
    end
  end

  # Grace notes before the first and before an inner member of a beam, and
  # inside a triplet.
  def graces_in_beams
    HeadMusic::Notation::ABC.parse("X:1\nT:Graces\nM:2/4\nL:1/8\nK:C\n{A,}C{B,}D E{^F}G |]\n").tap do |flow|
      voice = flow.voices.first
      TupletFixtures.fill(voice, [*TupletFixtures.run("3:2", :eighth, %w[C4 D4 E4]), [:quarter, "F4"]])
      voice.voice_events[5].add_grace_note("C4", :sixteenth)
      TupletFixtures.group(voice, 4, 6)
    end
  end

  # A bracket across a barline in a piano's left hand, the part's second
  # voice, on its second staff.
  def left_hand_tuplet_across_barline
    TupletFixtures.flow("Left Hand").tap do |piano|
      right_hand, left_hand = TupletFixtures.piano_hands(piano)
      TupletFixtures.fill(right_hand, [[:whole, "C5"], [:whole, "D5"]])
      TupletFixtures.fill(left_hand, [["dotted half", "C3"], *TupletFixtures.run("3:2", :quarter, %w[D3 E3 F3]), ["dotted half", "G3"]])
      TupletFixtures.group(left_hand, 1, 3)
    end
  end

  def all
    %i[beams_across_tuplet tuplet_inside_beam graces_in_beams left_hand_tuplet_across_barline]
  end
end
