# What every rendered file must satisfy, as a player merging its tracks hears
# it: each note on meets exactly one later note off, no key is struck while
# it sounds, ticks never go back, and every track ends together with its
# end-of-track last.
module MIDIInvariants
  def midi_invariant_violations(sequence)
    track_violations(sequence) + key_violations(sequence.merged_events)
  end

  # Renders, decodes, and checks a flow, answering the decoded sequence.
  def render_midi(flow, **options)
    bytes = HeadMusic::MIDI.render(flow, **options)
    sequence = HeadMusic::MIDI::Reader.new(bytes).read
    expect(midi_invariant_violations(sequence)).to eq []
    sequence
  end

  private

  def track_violations(sequence)
    finishes = sequence.tracks.map { |track| track.events.last&.tick }
    violations = sequence.tracks.each_with_index.flat_map do |track, index|
      ticks = track.events.map(&:tick)
      [
        ("track #{index} goes back in time" unless ticks.each_cons(2).all? { |earlier, later| earlier <= later }),
        ("track #{index} does not end with its end-of-track" unless track.terminated),
        ("track #{index} has more than one end-of-track" if track.of(HeadMusic::MIDI::EndOfTrack).length > 1)
      ].compact
    end
    violations << "tracks end at different ticks" unless finishes.uniq.length == 1
    violations
  end

  def key_violations(events)
    held = {}
    violations = events.each_with_object([]) do |event, found|
      key = [event.channel, event.key] if event.respond_to?(:key)
      case event
      when HeadMusic::MIDI::NoteOn
        found << "key #{event.key} on channel #{event.channel} struck at #{event.tick} while it sounds" if held[key]
        held[key] = event
      when HeadMusic::MIDI::NoteOff
        found << "key #{event.key} on channel #{event.channel} released at #{event.tick} while silent" unless held.delete(key)
      end
    end
    violations + held.values.map { |on| "key #{on.key} on channel #{on.channel} struck at #{on.tick} is never released" }
  end
end

RSpec.configure { |config| config.include MIDIInvariants }
