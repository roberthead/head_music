# The compositions the LilyPond writer specs render, shared with the parser's
# round-trip specs so every fixture shape the writer emits is also proven to
# read back. Each method builds a fresh composition.
module LilyPondFixtures
  module_function

  def speed_the_plough
    HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH)
  end

  def chromatic_air
    HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR)
  end

  def rests
    composition = HeadMusic::Content::Composition.new(name: "Rests")
    voice = composition.add_voice
    voice.place("1:1", :quarter, "C4")
    voice.place("1:2", :quarter)
    voice.place("1:3", :half, "E4")
    composition
  end

  def duo
    composition = HeadMusic::Content::Composition.new(name: "Duo", key_signature: "C major", meter: "4/4")
    upper = composition.add_voice(role: "Melody")
    upper.place("1:1", :whole, "E5")
    upper.place("2:1", :whole, "D5")
    lower = composition.add_voice(role: "Bass line")
    lower.place("1:1", :whole, "C3")
    composition
  end

  def key_and_meter_change
    composition = HeadMusic::Content::Composition.new(name: "Turn", key_signature: "G major", meter: "4/4")
    %w[G4 G3].each do |pitch|
      voice = composition.add_voice
      voice.place("1:1", :whole, pitch)
      voice.place("2:1", :whole, pitch)
      voice.place("3:1", "dotted half", pitch)
    end
    composition.change_key_signature(3, "D major")
    composition.change_meter(3, "3/4")
    composition
  end

  def tacet
    composition = HeadMusic::Content::Composition.new(name: "Tacet")
    composition.add_voice
    composition
  end

  def song
    composition = HeadMusic::Content::Composition.new(name: "Song")
    composition.add_voice.place("1:1", :whole, "C4").sing("shenandoah")
    composition
  end

  def escaped_header
    composition = HeadMusic::Content::Composition.new(
      name: %(The "Great" \\ Escape), composer: %(A. "Slash" Author)
    )
    composition.add_voice.place("1:1", :whole, "C4")
    composition
  end

  def anonymous
    composition = HeadMusic::Content::Composition.new(name: "Anon")
    composition.add_voice.place("1:1", :whole, "C4")
    composition
  end

  def air
    composition = HeadMusic::Content::Composition.new(
      name: "Air", key_signature: "G major", meter: "4/4", composer: "Aloysius"
    )
    voice = composition.add_voice(role: "Melody")
    voice.place("1:1", :quarter, "G4")
    voice.place("1:2", :quarter, "A4")
    voice.place("1:3", :quarter, "B4")
    voice.place("1:4", :quarter, "C5")
    voice.place("2:1", :half, "D5")
    voice.place("2:3", :half, "G4")
    composition
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
