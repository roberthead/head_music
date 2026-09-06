# The flows the LilyPond writer specs render, shared with the parser's
# round-trip specs so every fixture shape the writer emits is also proven to
# read back. Each method builds a fresh flow.
module LilyPondFixtures
  module_function

  def speed_the_plough
    HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH)
  end

  def chromatic_air
    HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR)
  end

  # A piano part on a grand staff whose left hand rises into the treble staff
  # for two bars. Deliberately not in the round-trip set: the reader has no
  # notion of a staff group, so this fixture is a writer fixture only.
  def cross_staff_piano
    flow = HeadMusic::Content::Flow.new(name: "Cross Staff", key_signature: "C major", meter: "4/4")
    staff_system = HeadMusic::Content::StaffSystem.grand_staff
    treble, bass = staff_system.staves
    piano = flow.add_part(instrument: "piano", staff_system: staff_system)
    right_hand = piano.add_voice(role: "right hand")
    left_hand = piano.add_voice(role: "left hand")
    left_hand.cross_to(bass, from: 1)
    (1..4).each do |bar|
      right_hand.place("#{bar}:1", :whole, "E5")
      left_hand.place("#{bar}:1", :whole, "C3")
    end
    left_hand.cross_to(treble, from: 2, through: 3)
    flow
  end

  # A grand staff with only a right hand, so the bass staff carries nobody.
  def one_handed_piano
    flow = HeadMusic::Content::Flow.new(name: "One Hand", key_signature: "C major", meter: "4/4")
    piano = flow.add_part(instrument: "piano", staff_system: HeadMusic::Content::StaffSystem.grand_staff)
    right_hand = piano.add_voice(role: "right hand")
    (1..2).each { |bar| right_hand.place("#{bar}:1", :whole, "E5") }
    flow
  end

  def rests
    flow = HeadMusic::Content::Flow.new(name: "Rests")
    voice = flow.add_voice
    voice.place("1:1", :quarter, "C4")
    voice.place("1:2", :quarter)
    voice.place("1:3", :half, "E4")
    flow
  end

  def duo
    flow = HeadMusic::Content::Flow.new(name: "Duo", key_signature: "C major", meter: "4/4")
    upper = flow.add_voice(role: "Melody")
    upper.place("1:1", :whole, "E5")
    upper.place("2:1", :whole, "D5")
    lower = flow.add_voice(role: "Bass line")
    lower.place("1:1", :whole, "C3")
    flow
  end

  def key_and_meter_change
    flow = HeadMusic::Content::Flow.new(name: "Turn", key_signature: "G major", meter: "4/4")
    %w[G4 G3].each do |pitch|
      voice = flow.add_voice
      voice.place("1:1", :whole, pitch)
      voice.place("2:1", :whole, pitch)
      voice.place("3:1", "dotted half", pitch)
    end
    flow.change_key_signature(3, "D major")
    flow.change_meter(3, "3/4")
    flow
  end

  def tacet
    flow = HeadMusic::Content::Flow.new(name: "Tacet")
    flow.add_voice
    flow
  end

  def song
    flow = HeadMusic::Content::Flow.new(name: "Song")
    flow.add_voice.place("1:1", :whole, "C4").sing("shenandoah")
    flow
  end

  def escaped_header
    flow = HeadMusic::Content::Flow.new(
      name: %(The "Great" \\ Escape), composer: %(A. "Slash" Author)
    )
    flow.add_voice.place("1:1", :whole, "C4")
    flow
  end

  def anonymous
    flow = HeadMusic::Content::Flow.new(name: "Anon")
    flow.add_voice.place("1:1", :whole, "C4")
    flow
  end

  def air
    flow = HeadMusic::Content::Flow.new(
      name: "Air", key_signature: "G major", meter: "4/4", composer: "Aloysius"
    )
    voice = flow.add_voice(role: "Melody")
    voice.place("1:1", :quarter, "G4")
    voice.place("1:2", :quarter, "A4")
    voice.place("1:3", :quarter, "B4")
    voice.place("1:4", :quarter, "C5")
    voice.place("2:1", :half, "D5")
    voice.place("2:3", :half, "G4")
    flow
  end

  # The exact document the writer renders for #air.
  AIR_DOCUMENT = <<~LILYPOND
    \\version "2.24.0"
    \\header {
      title = "Air"
      composer = "Aloysius"
    }
    \\score {
      <<
        \\new Staff \\with { instrumentName = "Melody" } {
          \\new Voice {
            \\clef treble
            \\key g \\major
            \\time 4/4
            g'4 a'4 b'4 c''4 |
            d''2 g'2 |
          }
        }
      >>
      \\layout { }
    }
  LILYPOND
end
