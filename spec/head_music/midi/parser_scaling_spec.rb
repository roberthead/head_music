require "spec_helper"

# Parsing runs in linear time: doubling the bars at most doubles the calls
# to the methods that build positions, look up meters, record timeline
# changes, allocate bars, place and tie values, and weigh voices, with the
# blocks each runs, and the calls the whole parse makes. Every voice is
# placed in order, so none is ever revised. It counts calls rather than
# timing them.
describe HeadMusic::MIDI::Parser do
  def ticks_per_bar
    384
  end

  def counted
    {
      position: [HeadMusic::Content::Position, :initialize],
      meter_at: [HeadMusic::Content::Flow, :meter_at],
      event_map_add: [HeadMusic::Time::EventMap, :add],
      bars_span: [HeadMusic::Content::Flow::Bars, :span],
      place: [HeadMusic::Content::Voice, :place],
      rhythmic_duration: [HeadMusic::Rudiment::RhythmicDuration, :initialize],
      voice_distance: [HeadMusic::MIDI::VoiceSeparator.const_get(:Lane), :mean_key]
    }
  end

  # Each counted method's calls, every call the parse makes, and the flow.
  def measure(bytes)
    counts = Hash.new(0)
    traces = counted.map do |name, (owner, method)|
      TracePoint.new(:call, :b_call) { counts[name] += 1 }.tap { |trace| trace.enable(target: owner.instance_method(method)) }
    end
    flow = TracePoint.new(:call, :b_call, :c_call) { counts[:total] += 1 }.enable { HeadMusic::MIDI.parse(bytes) }
    [counts, flow]
  ensure
    traces&.each(&:disable)
  end

  def ratios(small, large)
    (counted.keys + [:total]).to_h { |name| [name, small[name].zero? ? 1.0 : large[name].fdiv(small[name]).round(2)] }
  end

  # Parses once to load what is loaded on first use, then at N and 2N bars.
  def scaling(bars)
    HeadMusic::MIDI.parse(yield(bars))
    (small, _), (large, flow) = measure(yield(bars)), measure(yield(bars * 2))
    [ratios(small, large), flow, small]
  end

  # Four lines on one channel, each with a rhythm of its own, so that they
  # overlap and never sound together as a chord.
  def four_voices(bars)
    rhythms = {84 => 96, 72 => 192, 60 => 128, 48 => 384}
    smf(rhythms.flat_map { |key, length| (0...(bars * ticks_per_bar / length)).flat_map { |index| midi_note(index * length, key + (index % 3), length) } })
  end

  def held_note(bars)
    smf(midi_note(0, 60, bars * ticks_per_bar))
  end

  def tempo_and_key_changes(bars)
    smf((0...bars).flat_map { |bar| [tempo(bar * ticks_per_bar, 400_000 + (bar % 2) * 100_000), key_signature(bar * ticks_per_bar, (bar % 2).zero? ? 2 : -3), *midi_note(bar * ticks_per_bar, 62, ticks_per_bar)] })
  end

  def meter_changes(bars)
    tick = 0
    events = (0...bars).flat_map do |bar|
      numerator = bar.even? ? 4 : 3
      length = numerator * 96
      [time_signature(tick, numerator, 4), *midi_note(tick, 60, length)].tap { tick += length }
    end
    smf(events)
  end

  # As many notes as a part may have voices, struck in turn and never
  # released, so each sounds to the end of the track.
  def unreleased_at_the_cap(bars)
    cap = HeadMusic::MIDI::Budget::MAX_VOICES_PER_PART
    notes = (0...cap).map { |index| HeadMusic::MIDI::NoteOn.new(index * 6, 0, 30 + index, 80) }
    smf([*notes, HeadMusic::MIDI::EndOfTrack.new(bars * ticks_per_bar)])
  end

  def twelve_note_chords(bars)
    smf((0...(bars * 4)).flat_map { |beat| (0...12).flat_map { |step| midi_note(beat * 96, 48 + step * 2, 96) } })
  end

  {
    "N bars of four voices" => [:four_voices, 40],
    "one note held for N bars" => [:held_note, 200],
    "N tempo changes and N key changes" => [:tempo_and_key_changes, 100],
    "N time-signature changes at barlines" => [:meter_changes, 100],
    "unreleased notes at the voice cap" => [:unreleased_at_the_cap, 40],
    "12-note chords at every onset" => [:twelve_note_chords, 40]
  }.each do |shape, (generator, bars)|
    it "reads #{shape} in linear time, revising no voice" do
      ratios, flow, = scaling(bars) { |count| send(generator, count) }
      expect(ratios.values).to all(be <= 2.2), ratios.inspect
      expect(flow.voices.map(&:revision)).to all(be_zero)
    end
  end
end
