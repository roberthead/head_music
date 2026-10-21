# Seeded random flows with hairpins, for round trips that hunt what the
# fixtures miss. Notes cross barlines as tied links, rests split at them,
# hairpins touch on those links, and their ends fall inside notes, where the
# music ends, and on the final barline.
#
# Run more seeds locally with HAIRPIN_SEEDS=1..2000.
class HairpinGenerator
  SEEDS = Range.new(*ENV.fetch("HAIRPIN_SEEDS", "1..100").split("..").map(&:to_i))
  VALUES = {quarter: 1/4r, half: 1/2r, dotted_half: 3/4r, whole: 1r}.freeze
  PITCHES = %w[C4 D4 E4 F4 G4 A4 B4 C5].freeze
  GRID = 1/16r
  TICKS_PER_COUNT = HeadMusic::Rudiment::Rhythm::PPQN

  # With `one_line`, no two of a part's hairpins overlap across its owners,
  # as the ABC voice that writes its part's hairpins and kern's single
  # **dynam spine need.
  def self.flow(seed, voices: 2, one_line: false, pickup: true)
    new(Random.new(seed), voices: voices, one_line: one_line, pickup: pickup).flow
  end

  attr_reader :flow

  def initialize(random, voices:, one_line:, pickup:)
    @random = random
    @flow = HeadMusic::Content::Flow.new(name: "Generated", key_signature: "C major", meter: "4/4")
    @start = (pickup && random.rand < 0.4) ? -1 : 0
    @music_end = random.rand(2..4) - [0, 0, 1/4r, 1/2r].sample(random: random)
    @final_barline = @music_end.ceil
    build_voices(voices)
    add_hairpins(one_line)
  end

  private

  attr_reader :random

  def build_voices(count)
    if count == 1
      fill(flow.add_voice)
    else
      staff_system = HeadMusic::Content::StaffSystem.grand_staff
      part = flow.add_part(instrument: "piano", staff_system: staff_system)
      upper = part.add_voice(role: "right hand")
      lower = part.add_voice(role: "left hand")
      lower.cross_to(staff_system.staves.last, from: @start + 1)
      [upper, lower].each { |voice| fill(voice) }
    end
  end

  # Values from the quarter grid only, so every piece a barline cuts is a
  # value each format can write.
  def fill(voice)
    time = @start.to_r
    while time < @music_end
      room = @music_end - time
      name, value = VALUES.select { |_, length| length <= room }.to_a.sample(random: random)
      voice.place(position(time), name, (random.rand < 0.2) ? nil : PITCHES.sample(random: random))
      time += value
    end
  end

  def add_hairpins(one_line)
    owners = [flow.parts.first, *flow.voices]
    if one_line
      chain(random.rand(0..4)).each { |from, to, kind| owners.sample(random: random).add_span(kind, from: from, to: to) }
    else
      owners.each { |owner| chain(random.rand(0..3)).each { |from, to, kind| owner.add_span(kind, from: from, to: to) } }
    end
  end

  # Hairpins that never overlap, each touching the last now and then, and
  # one in four seeds touching on the later link of a tied note.
  def chain(count)
    hairpins = []
    cursor = ((random.rand < 0.25) && tie_link_time) || start_time(@start)
    while hairpins.length < count && cursor
      to = end_time_after(cursor)
      hairpins << [position(cursor), position(to), %i[crescendo diminuendo].sample(random: random)]
      cursor = (random.rand < 0.4) ? to : start_time(to + GRID)
      cursor = nil unless cursor && cursor < @music_end
    end
    hairpins
  end

  def start_time(from)
    grid_time(from, @music_end - GRID)
  end

  def end_time_after(time)
    return @final_barline if random.rand < 0.15

    grid_time(time + GRID, @music_end)
  end

  def tie_link_time
    barlines = (@start + 1...@music_end.ceil).map(&:to_r)
    barlines.select { |barline| flow.voices.any? { |voice| tied_across?(voice, position(barline)) } }.sample(random: random)
  end

  def tied_across?(voice, barline)
    event = voice.voice_event_sounding_at(barline)
    !event.nil? && event.position < barline
  end

  def grid_time(from, to)
    steps = ((to - from) / GRID).floor
    return if steps.negative?

    from + GRID * random.rand(0..steps)
  end

  def position(time)
    bar = time.floor
    within = (time - bar) * 4
    count = within.floor
    ticks = ((within - count) * TICKS_PER_COUNT).to_i
    flow.position(bar + 1, count + 1, ticks)
  end
end
