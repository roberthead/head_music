# Builds Standard MIDI Files event by event for the import specs, at 96
# ticks to the quarter unless told otherwise.
module MIDIBytes
  DIVISION = 96

  def smf(*tracks, division: DIVISION, format: 1)
    bytes = HeadMusic::MIDI::SMF.file(division: division, tracks: tracks)
    bytes.setbyte(9, format)
    bytes
  end

  # A note on and its note off, +length+ in ticks.
  def midi_note(tick, key, length, channel: 0, velocity: 80)
    [HeadMusic::MIDI::NoteOn.new(tick, channel, key, velocity), HeadMusic::MIDI::NoteOff.new(tick: tick + length, channel: channel, key: key)]
  end

  # One note after another on a channel, each +length+ ticks, from +tick+.
  def midi_line(keys, length, tick: 0, channel: 0)
    keys.each_with_index.flat_map { |key, index| midi_note(tick + index * length, key, length, channel: channel) }
  end

  def track_name(name, tick: 0)
    HeadMusic::MIDI::Text.new(tick, :track_name, name)
  end

  def lyric(tick, text)
    HeadMusic::MIDI::Text.new(tick, :lyric, text)
  end

  def program(tick, program, channel: 0)
    HeadMusic::MIDI::ProgramChange.new(tick, channel, program)
  end

  def time_signature(tick, numerator, denominator)
    HeadMusic::MIDI::TimeSignature.new(tick, numerator, denominator, 24)
  end

  def tempo(tick, microseconds)
    HeadMusic::MIDI::Tempo.new(tick, microseconds)
  end

  def key_signature(tick, fifths, minor: false)
    HeadMusic::MIDI::KeySignature.new(tick, fifths, minor)
  end

  # A rendered file with every event of some kinds taken out.
  def without(bytes, *kinds)
    sequence = HeadMusic::MIDI::Reader.new(bytes).read
    tracks = sequence.tracks.map { |track| track.events.reject { |event| kinds.any? { |kind| event.is_a?(kind) } } }
    HeadMusic::MIDI::SMF.file(division: sequence.division, tracks: tracks)
  end

  def bar_events(voice)
    voice.voice_events.map { |event| [event.position.to_s, event.rhythmic_duration.to_s, event.rest? ? "rest" : event.sounds.join(" ")] }
  end
end

RSpec.configure { |config| config.include MIDIBytes }
