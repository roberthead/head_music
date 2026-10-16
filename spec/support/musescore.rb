require "fileutils"
require "rexml/document"
require "tmpdir"
require_relative "abc_fixtures"
require_relative "layout_fixtures"
require_relative "lily_pond_fixtures"
require_relative "marking_fixtures"
require_relative "navigation_fixtures"
require_relative "tuplet_fixtures"

# Runs MuseScore 4 headlessly. Its exit status is unreliable (0 on one run,
# 134 on the next, with the file written both times), so a conversion is
# judged by its output alone.
module MuseScore
  APPLICATION_PATH = "/Applications/MuseScore 4.app/Contents/MacOS/mscore"

  class ConversionError < StandardError; end

  module_function

  def executable
    from_environment = ENV["MSCORE"].to_s
    return from_environment unless from_environment.empty?

    APPLICATION_PATH if File.executable?(APPLICATION_PATH)
  end

  def available?
    !executable.nil?
  end

  # Answers MuseScore's MusicXML for a MusicXML string.
  def convert(musicxml)
    Dir.mktmpdir("musescore") do |directory|
      source = File.join(directory, "source.musicxml")
      File.write(source, musicxml)
      convert_file(source, File.join(directory, "converted.musicxml"))
    end
  end

  # Writes MuseScore's conversion of one file to another, in the format the
  # target's extension names, and answers it: bytes for a MIDI file, and
  # otherwise well-formed MusicXML. A +timeout:+ in seconds kills a
  # conversion that hangs, as MuseScore does on MEI it cannot read.
  def convert_file(source, target, timeout: nil)
    raise ConversionError, "MuseScore not found; set MSCORE to its executable" unless available?

    FileUtils.rm_f(target)
    run_mscore(source, target, timeout)
    raise ConversionError, "MuseScore wrote nothing for #{source}" unless File.exist?(target)
    return File.binread(target) if File.extname(target) == ".mid"

    converted = File.read(target)
    raise ConversionError, "MuseScore wrote malformed XML for #{source}" unless well_formed?(converted)

    converted
  end

  def run_mscore(source, target, timeout)
    pid = Process.spawn(executable, "-o", target, source, out: File::NULL, err: File::NULL)
    return Process.wait(pid) unless timeout

    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    until Process.wait(pid, Process::WNOHANG)
      next sleep(0.05) if Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline

      Process.kill("KILL", pid)
      Process.wait(pid)
      raise ConversionError, "MuseScore did not finish #{source} within #{timeout} seconds"
    end
  end

  def well_formed?(xml)
    !REXML::Document.new(xml).root.nil?
  rescue REXML::ParseException
    false
  end
end

# The head_music renders that MuseScore converts for the committed fixtures
# in spec/fixtures/notation/music_xml/. Between them they carry every feature
# the MusicXML writer emits.
module MuseScoreFixtures
  DIRECTORY = File.expand_path("../fixtures/notation/music_xml", __dir__)
  LILY_POND_DIRECTORY = File.expand_path("../fixtures/notation/lily_pond", __dir__)

  RENDERS = {
    "speed_the_plough" => -> { render(HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH)) },
    "bach_invention_01" => -> { render(lily_pond("bach_invention_01")) },
    "cross_staff_piano" => -> { render(LilyPondFixtures.cross_staff_piano) },
    "piano_part_marks" => -> { render(piano_part_marks) },
    "marked_dal_segno_al_coda" => -> { render(marked_dal_segno_al_coda) },
    "marked_da_capo_al_fine" => -> { render(marked_da_capo_al_fine) },
    "barline_styles" => -> { render(LilyPondFixtures.barline_styles) },
    "key_and_meter_change" => -> { render(LilyPondFixtures.key_and_meter_change) },
    "clef_changes" => -> { render(clef_changes) },
    "triplets" => -> { render(TupletFixtures.triplets) },
    "grace_notes_before_downbeat" => -> { render(TupletFixtures.grace_notes_before_downbeat) },
    "two_verses" => -> { render(two_verses) },
    "clarinet_changes" => -> { render(clarinet_changes.flows.first) },
    "clarinet_changes_transposed" => -> { clarinet_changes.add_layout(concert_pitch: false).to_musicxml }
  }.freeze

  # The renders converted to score-timewise with Dorico's XSLT.
  TIMEWISE = %w[speed_the_plough key_and_meter_change].freeze

  module_function

  def names
    RENDERS.keys
  end

  def musicxml(name)
    RENDERS.fetch(name).call
  end

  def path(name, kind)
    File.join(DIRECTORY, "#{name}.#{kind}.musicxml")
  end

  def render(flow)
    HeadMusic::Notation::MusicXML.render(flow)
  end

  def lily_pond(name)
    HeadMusic::Notation::LilyPond.parse(File.read(File.join(LILY_POND_DIRECTORY, "#{name}.ly")))
  end

  # The grand-staff piano's part and right-hand dynamics, with the part's own
  # hairpins and one of the right hand's.
  def piano_part_marks
    MarkingFixtures.grand_staff_piano_with_dynamics.tap do |flow|
      piano = flow.parts.first
      piano.add_span(:crescendo, from: "1:1", to: "2:3")
      flow.voices.first.add_span(:crescendo, from: "2:3", to: "3:1")
      piano.add_span(:diminuendo, from: "3:1", to: "5:1")
    end
  end

  # Segno, To Coda, D.S. al Coda, the coda, and rehearsal marks, under
  # articulations, ornaments, note dynamics, levels, slurs, a phrase mark,
  # and hairpins, one ending on the final barline.
  def marked_dal_segno_al_coda
    NavigationFixtures.dal_segno_al_coda.tap do |flow|
      voice = flow.voices.first
      event = ->(code) { voice.voice_event_at(flow.position(code)) }
      %w[1:1 1:2 1:3].each { |code| event.call(code).articulate(:staccato) }
      event.call("1:4").articulate(:tenuto)
      event.call("2:2").articulate(:accent)
      event.call("2:4").embellish(:trill)
      event.call("3:1").embellish(:mordent).note_dynamic = :sfz
      event.call("3:3").embellish(:inverted_mordent).articulate(:staccatissimo)
      event.call("3:4").articulate(:marcato)
      event.call("4:1").embellish(:turn).note_dynamic = :fp
      voice.place_dynamic("1:1", :p)
      voice.place_dynamic("2:1", :mf)
      voice.place_dynamic("5:1", :pp)
      voice.add_span(:slur, from: "1:1", to: "1:3")
      voice.add_span(:phrase, from: "2:1", to: "2:4")
      voice.add_span(:crescendo, from: "1:2", to: "2:1")
      voice.add_span(:diminuendo, from: "4:1", to: "4:4")
      voice.add_span(:crescendo, from: "5:1", to: "6:1")
    end
  end

  # A repeat with first and second endings, a Fine, and D.C. al Fine, under
  # levels, hairpins, a slur, and an accent.
  def marked_da_capo_al_fine
    NavigationFixtures.da_capo_al_fine.tap do |flow|
      voice = flow.voices.first
      voice.place_dynamic("1:1", :mf)
      voice.place_dynamic("4:1", :p)
      voice.add_span(:crescendo, from: "4:1", to: "5:1")
      voice.add_span(:diminuendo, from: "6:1", to: "7:1")
      voice.add_span(:slur, from: "5:1", to: "5:3")
      voice.voice_event_at(flow.position("7:1")).articulate(:accent)
    end
  end

  # A cello moving into tenor clef and back, over a tenor voice on the
  # octave treble clef.
  def clef_changes
    HeadMusic::Content::Flow.new(name: "Clef Changes", key_signature: "C major", meter: "4/4").tap do |flow|
      tenor = flow.add_part(staff_system: HeadMusic::Content::StaffSystem.single_staff(clef: :vocal_tenor_clef))
      cello = flow.add_part(instrument: "cello")
      {tenor => %w[C4 D4 E4 F4 E4 C4], cello => %w[C3 G3 D4 E4 A3 C3]}.each do |part, pitches|
        voice = part.add_voice
        pitches.each_with_index { |pitch, index| voice.place("#{index + 1}:1", :whole, pitch) }
      end
      cello.staff_system.staves.first.change_clef(3, :tenor_clef)
      cello.staff_system.staves.first.change_clef(5, :bass_clef)
    end
  end

  # The opening of New Britain ("Amazing Grace", John Newton, 1779) with its
  # first two verses, a pickup, hyphens, and two-note melismas.
  def two_verses
    HeadMusic::Content::Flow.new(name: "Amazing Grace", key_signature: "F major", meter: "3/4").tap do |flow|
      voice = flow.add_voice(role: "melody")
      voice.place("0:1", :half)
      notes = [
        [:quarter, "C4", ["A", true], ["'Twas", false]],
        [:half, "F4", ["ma", true], ["grace", false]],
        [:eighth, "A4", ["zing", false], ["that", false]],
        [:eighth, "F4"],
        [:half, "A4", ["grace", false], ["taught", false]],
        [:quarter, "G4", ["how", false], ["my", false]],
        [:half, "F4", ["sweet", false], ["heart", false]],
        [:quarter, "D4", ["the", false], ["to", false]],
        [:half, "C4", ["sound", false], ["fear,", false]],
        [:quarter, "C4", ["that", false], ["and", false]],
        [:half, "F4", ["saved", false], ["grace", false]],
        [:eighth, "A4", ["a", false], ["my", false]],
        [:eighth, "F4"],
        [:half, "A4", ["wretch", false], ["fears", false]],
        [:quarter, "G4", ["like", false], ["re", true]],
        [:dotted_half, "C5", ["me.", false], ["lieved.", false]]
      ]
      notes.each do |rhythmic_value, pitch, *verses|
        event = voice.place(voice.next_position, rhythmic_value, pitch)
        verses.each.with_index(1) { |(text, hyphen_after), verse| event.sing(text, verse: verse, hyphen_after: hyphen_after) }
      end
    end
  end

  # A B-flat clarinet that picks up an A clarinet in bar 3 and a flute in
  # bar 5, so the transposition changes twice and then resets. No grace
  # notes, which a transposed layout does not yet transpose.
  def clarinet_changes
    LayoutFixtures.clarinet_project(pitches: %w[C4 D4 E4 F4 G4 A4]).tap do |project|
      part = project.flows.first.parts.first
      part.change_instrument(3, "clarinet_in_a")
      part.change_instrument(5, "flute")
    end
  end
end
