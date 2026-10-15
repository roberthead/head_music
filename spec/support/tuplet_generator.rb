# Seeded random flows with tuplets and grace notes, for round trips that hunt
# what the fixtures miss. Groups of each ratio fill a quarter or a half, hold
# rests, chords, and mixed values, and sometimes start on the last beat and
# cross the barline at their midpoint, where every piece stays writable under
# the ratio. Grace notes come before about one note in five, sometimes under a
# slur from the first of them.
#
# Run more seeds locally with TUPLET_SEEDS=1..2000.
class TupletGenerator
  SEEDS = Range.new(*ENV.fetch("TUPLET_SEEDS", "1..100").split("..").map(&:to_i))
  PITCHES = %w[C4 D4 E4 F4 G4 A4 B4 C5].freeze
  GRACE_PITCHES = %w[D4 E4 F4 G4 A4 B4 C5 D5].freeze
  PLAIN_VALUES = {"eighth" => 1/8r, "quarter" => 1/4r, "dotted quarter" => 3/8r, "half" => 1/2r}.freeze

  # The written unit of each ratio's group by the span it fills.
  UNITS = {
    "3:2" => {1/4r => :eighth, 1/2r => :quarter},
    "6:4" => {1/4r => :sixteenth, 1/2r => :eighth},
    "5:4" => {1/4r => :sixteenth, 1/2r => :eighth},
    "7:4" => {1/4r => :sixteenth, 1/2r => :eighth},
    "2:3" => {3/8r => :eighth}
  }.freeze

  def self.flow(seed, voices: 2, cross_barlines: true, ratios: %w[3:2 6:4 5:4 7:4], meters: %w[4/4 6/8],
    ungrouped: true, graces: true, pickup: true)
    new(Random.new(seed), voices:, cross_barlines:, ratios:, meters:, ungrouped:, graces:, pickup:).flow
  end

  attr_reader :flow

  def initialize(random, voices:, cross_barlines:, ratios:, meters:, ungrouped:, graces:, pickup:)
    @random = random
    @options = {cross_barlines:, ratios:, ungrouped:, graces:}
    @flow = HeadMusic::Content::Flow.new(name: "Generated", key_signature: "C major", meter: meters.sample(random: random))
    meter = flow.meter
    @bar_length = Rational(meter.top_number, meter.bottom_number)
    @start = (pickup && random.rand < 0.4) ? -@bar_length : 0r
    @music_end = @bar_length * random.rand(2..4)
    build_voices(voices)
  end

  private

  attr_reader :random, :options

  def build_voices(count)
    voices = (count == 1) ? [flow.add_voice] : TupletFixtures.piano_hands(flow, from: first_bar)
    voices.each { |voice| fill(voice) }
  end

  def fill(voice)
    time = @start
    first_position = flow.position(first_bar, 1, 0)
    while time < @music_end
      length = place_tuplet(voice, time, first_position) || place_plain(voice, time, first_position)
      time += length
    end
  end

  def place_tuplet(voice, time, first_position)
    return unless random.rand < 0.4

    choice = tuplet_choice(time)
    return unless choice

    ratio, span = choice
    from = position_at(voice, first_position)
    links_for(ratio, span).each { |value| place(voice, value, first_position) }
    group = !options[:ungrouped] || random.rand < 0.75
    voice.group_tuplet(from: from, to: voice.next_position) if group
    span
  end

  # A ratio and a span that fit here: within the bar, or across its barline
  # at the span's midpoint when that is allowed.
  def tuplet_choice(time)
    room = room_in_bar(time)
    choices = options[:ratios].flat_map { |ratio| UNITS.fetch(ratio).keys.map { |span| [ratio, span] } }
    choices.select { |_, span| fits?(time, span, room) }.sample(random: random)
  end

  def fits?(time, span, room)
    return false if time + span > @music_end
    return true if span <= room

    options[:cross_barlines] && room == span / 2
  end

  # A group's written values: its unit, its actual count of them, and now and
  # then two units merged into one value of twice the length.
  def links_for(ratio_name, span)
    ratio = HeadMusic::Rudiment::TupletRatio.get(ratio_name)
    unit = HeadMusic::Rudiment::RhythmicValue.get(UNITS.fetch(ratio_name).fetch(span))
    units = Array.new(ratio.actual, 1)
    if ratio.actual > 2 && random.rand < 0.3
      index = random.rand(0...(ratio.actual - 1))
      units[index, 2] = [2]
    end
    units.map { |count| HeadMusic::Notation::DottedDuration.rhythmic_value_for(unit.written_fraction * count * ratio.factor, tuplet: ratio) }
  end

  def place_plain(voice, time, first_position)
    room = room_in_bar(time)
    name, length = PLAIN_VALUES.select { |_, value| value <= room && time + value <= @music_end }.to_a.sample(random: random)
    name, length = PLAIN_VALUES.select { |_, value| time + value <= @music_end }.to_a.min_by(&:last) unless name
    place(voice, HeadMusic::Rudiment::RhythmicValue.get(name), first_position)
    length
  end

  def place(voice, rhythmic_value, first_position)
    voice_event = voice.place(position_at(voice, first_position), rhythmic_value, sounds)
    add_grace_notes(voice, voice_event) if options[:graces] && !voice_event.rest? && random.rand < 0.2
    voice_event
  end

  def sounds
    roll = random.rand
    return if roll < 0.2
    return PITCHES.sample(2, random: random).sort_by { |name| HeadMusic::Rudiment::Pitch.get(name) } if roll < 0.3

    PITCHES.sample(random: random)
  end

  def add_grace_notes(voice, voice_event)
    count = (random.rand < 0.7) ? 1 : 2
    slashed = count == 1 && random.rand < 0.6
    count.times do |index|
      last = index == count - 1
      tied = last && voice_event.pitched_note? && random.rand < 0.2
      pitch = tied ? voice_event.pitch : grace_sounds
      articulations = (random.rand < 0.15) ? [:staccato] : []
      voice_event.add_grace_note(pitch, (random.rand < 0.5) ? :sixteenth : :eighth, slashed:, tied:, articulations:)
    end
    voice.add_span(:slur, from: voice_event.position, to: voice_event.position, from_grace: true) if random.rand < 0.3
  end

  def grace_sounds
    (random.rand < 0.15) ? GRACE_PITCHES.sample(2, random: random).sort_by { |name| HeadMusic::Rudiment::Pitch.get(name) } : GRACE_PITCHES.sample(random: random)
  end

  def first_bar
    @start.negative? ? 0 : 1
  end

  def room_in_bar(time)
    @bar_length - (time % @bar_length)
  end

  # The voice's next position, which the run rule rounds, or the first.
  def position_at(voice, first_position)
    voice.voice_events.empty? ? first_position : voice.next_position
  end
end
