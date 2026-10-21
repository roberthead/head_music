# ABC tunes holding the timeline expressions a format round-trips, and a
# comparison of two flows' timelines that leaves out what a format cannot
# hold.
#
# The melody is one voice, so ABC can write it: common time, an opening tempo
# with text, a tempo change with text, a "rit." to a written target at a
# downbeat, an "a tempo", an "accel." ending at a fermata on a rest, and a
# fermata on a note. The chorale is two voices in cut time, counting half
# notes: a soprano quarter held over the second of a bass eighth pair, and a
# "rit." ending in the middle of the last bar at a fermata on both voices'
# last notes. The fixture spec pins what each reads as.
module TimelineExpressionFixtures
  MELODY = <<~ABC
    X:1
    T:Timeline Melody
    M:C
    L:1/4
    Q:"Allegro" 1/4=120
    K:G
    G A B c|d2 Hd2|[Q:"Meno mosso" 1/4=96]e d "^rit."c B|[Q:1/4=72]A G "^a tempo"F G|
    A B "^accel."c d|e2 Hz2|]
  ABC

  CHORALE = <<~ABC
    X:1
    T:Timeline Chorale
    M:C|
    L:1/4
    Q:1/2=60
    V:S
    V:B
    K:D
    V:S
    f e d c|d Hc B2|A B "^rit."c d|B2 Hd2|]
    V:B
    D E F A,|B, G,/ HA,/ G,2|F, G, A, B,|G,2 HD,2|]
  ABC

  # An alto half note tied over the bar line, held under two fermatas, as in
  # chorale 202: one from its start, under the soprano's last note, and one
  # from its later link, which only the alto sounds under. The alto comes
  # first, so a format that writes one voice writes it.
  TIED_UNDER_TWO_FERMATAS = {"A" => "C2 E2-|E2 F2|]", "S" => "c2 d2|]"}.freeze

  # What a format may leave out of the comparison:
  # - :stretch, a fermata's stretch, which only JSON and MIDI write;
  # - :ramps, the tempo ramps and "a tempo" points, leaving each bar's tempo;
  # - :tempo_text, the words of tempos, ramps, and "a tempo" points, and
  #   whether a tempo's number was written;
  # - :meter_symbols, the common- and cut-time symbols;
  # - :beat_values, a tempo's beat, comparing quarter notes per minute.
  OMISSIONS = %i[stretch ramps tempo_text meter_symbols beat_values].freeze

  module_function

  def melody
    HeadMusic::Notation::ABC.parse(MELODY)
  end

  def chorale
    HeadMusic::Notation::ABC.parse(CHORALE)
  end

  def tied_under_two_fermatas(voices: 2)
    bodies = TIED_UNDER_TWO_FERMATAS.first(voices)
    declarations = bodies.map { |name, _| "V:#{name}\n" }.join
    music = bodies.map { |name, body| "V:#{name}\n#{body}\n" }.join
    HeadMusic::Notation::ABC.parse("X:1\nT:Tied Under Two Fermatas\nM:4/4\nL:1/4\n#{declarations}K:C\n#{music}").tap do |flow|
      flow.add_fermata("1:3", :half)
      flow.add_fermata("2:1", :half)
    end
  end

  # By bar, the meter and the tempo as written; the ramps with their targets
  # resolved, so a target written as a tempo change at a ramp's end compares
  # equal to one written on the ramp; the "a tempo" points; and the fermatas.
  def timeline(flow, except: [])
    unknown = except - OMISSIONS
    raise ArgumentError, "unknown omissions #{unknown.inspect}; choose from #{OMISSIONS.inspect}" if unknown.any?

    bar_numbers = flow.earliest_bar_number..flow.last_sounding_bar_number
    {
      meters: bar_numbers.map { |bar_number| meter(flow.meter_at(bar_number), except) },
      tempos: bar_numbers.map { |bar_number| tempo(flow.tempo_at(bar_number), except) },
      tempo_ramps: except.include?(:ramps) ? [] : tempo_ramps(flow, except),
      a_tempos: except.include?(:ramps) ? [] : flow.a_tempos.map { |a_tempo| [a_tempo.position.to_s, *text(a_tempo.text, except)] },
      fermatas: flow.fermatas.map { |fermata| [fermata.from.to_s, fermata.to.to_s, *(fermata.stretch unless except.include?(:stretch))] }
    }
  end

  def meter(meter, except)
    [meter.to_s, *(meter.symbol unless except.include?(:meter_symbols))]
  end

  def tempo(tempo, except)
    pace = except.include?(:beat_values) ? [tempo.beats_per_minute * tempo.beat_value.fraction * 4] : [tempo.beat_value.to_s, tempo.beats_per_minute]
    [*pace, *(except.include?(:tempo_text) ? [] : [tempo.text, tempo.metronome_mark?])]
  end

  def text(words, except)
    except.include?(:tempo_text) ? [] : [words]
  end

  def tempo_ramps(flow, except)
    return [] if flow.tempo_ramps.empty?

    flow.conductor.tempo_ramps.map do |ramp|
      [ramp.from.to_a, ramp.to.to_a, tempo(ramp.to_tempo, except), *text(ramp.text, except)]
    end
  end
end

module TimelineExpressionMatchers
  # Compares the timelines TimelineExpressionFixtures.timeline describes,
  # leaving out each of +except+.
  def expect_same_timeline(original, round_tripped, except: [])
    expect(TimelineExpressionFixtures.timeline(round_tripped, except: except))
      .to eq TimelineExpressionFixtures.timeline(original, except: except)
  end
end

RSpec.configure do |config|
  config.include TimelineExpressionMatchers
end
