# A module for musical content
module HeadMusic::Content; end

# A flow is a continuous span of music with its own timeline: a movement, a
# song, a cue, or a single exercise.
#
# A flow may stand alone. Its project is optional, which is what lets a cantus
# firmus, a scale, or a parsed snippet be content without inventing a noun for
# it. What is not optional is containment below: every voice is in a part, and
# every part is in a flow.
class HeadMusic::Content::Flow
  SCHEMA_VERSION = 4

  attr_reader :name, :parts, :composer, :origin, :comments, :timeline
  attr_accessor :project

  delegate :meter_at, :key_signature_at, :tempo_at, to: :timeline
  delegate :meter_changes, :key_signature_changes, :tempo_changes, :meter_change_at, :tempo_change_at, to: :timeline

  def self.from_h(hash)
    HashDeserializer.new(hash).flow
  end

  # Read a schema v3 document.
  #
  # Retained read-only through 21.x so that persisted v3 data can be migrated
  # by reading and re-saving. Removed in 22.0.0.
  def self.from_v3_h(hash)
    V3HashDeserializer.new(hash).flow
  end

  def self.from_json(json)
    from_h(JSON.parse(json))
  end

  def initialize(name: nil, key_signature: nil, meter: nil, tempo: nil, composer: nil, origin: nil, comments: nil)
    ensure_attributes(name, key_signature, meter, tempo)
    @composer = composer
    @origin = origin
    @parts = []
    @comments = Array(comments).map { |text| HeadMusic::Content::Comment.new(self, text) }
  end

  # The voices of every part, in part order.
  def voices
    parts.flat_map(&:voices)
  end

  # @param player [HeadMusic::Content::Player, nil] the chair this part fills;
  #   a part with no player is simply a staff of music
  def add_part(player: nil, instrument: nil, staff_system: nil)
    HeadMusic::Content::Part
      .new(flow: self, player: player, instrument: instrument, staff_system: staff_system)
      .tap { |part| @parts << part }
  end

  # A voice of its own, in a part of its own. One part per voice is the shape
  # counterpoint wants, and the shape every reader produces on import.
  def add_voice(role: nil)
    add_part.add_voice(role: role)
  end

  def add_comment(text, position = nil)
    @comments << HeadMusic::Content::Comment.new(self, text, position)
    @comments.last
  end

  # A position in this flow, from a "bar:count:tick" code or its components.
  def position(code_or_bar, count = nil, tick = nil, subtick = nil)
    HeadMusic::Content::Position.new(self, code_or_bar, count, tick, subtick)
  end

  # The signature and meter the flow opens in. Both are the timeline's, so a
  # change at bar 1 is a change like any other rather than a rewrite of the
  # flow's own attributes.
  def key_signature
    timeline.opening_key_signature_event.key_signature
  end

  def meter
    timeline.opening_meter
  end

  def tempo
    timeline.opening_tempo
  end

  # The key signature authored in a bar, as distinct from the one in force
  # there. Nil in a bar nothing was authored in.
  def key_signature_change_at(bar_number)
    timeline.key_signature_change_at(bar_number)&.key_signature
  end

  def bars(last = latest_bar_number)
    @bars ||= []
    first = [earliest_bar_number, last].min
    (first..last).each do |bar_number|
      @bars[bar_number] ||= HeadMusic::Content::Bar.new(self, number: bar_number)
    end
    @bars[first..last]
  end

  # Allocating the bar as well as recording the change is what pulls the bar
  # range back to a pickup bar that no voice places into -- which is what makes
  # MusicXML mark it implicit.
  def change_key_signature(bar_number, key_signature, tonal_context: nil)
    Timeline.ensure_downbeat!(bar_number)
    bars(bar_number)
    timeline.change_key_signature(bar_number, key_signature, tonal_context: tonal_context)
  end

  def change_meter(bar_number, meter)
    Timeline.ensure_downbeat!(bar_number)
    bars(bar_number)
    timeline.change_meter(bar_number, meter)
  end

  def change_tempo(bar_number, tempo)
    Timeline.ensure_downbeat!(bar_number)
    bars(bar_number)
    timeline.change_tempo(bar_number, tempo)
  end

  def earliest_bar_number
    [voices.map(&:earliest_bar_number), first_allocated_bar_number, 1].flatten.compact.min
  end

  def latest_bar_number
    [voices.map(&:latest_bar_number), 1].flatten.max
  end

  def cantus_firmus_voice
    voices.detect(&:cantus_firmus?)
  end

  def counterpoint_voice
    voices.reject(&:cantus_firmus?).first
  end

  def to_s
    "#{name} — #{voices.count} #{(voices.count == 1) ? "voice" : "voices"}"
  end

  def to_abc(**options)
    HeadMusic::Notation::ABC.render(self, **options)
  end

  def to_musicxml
    HeadMusic::Notation::MusicXML.render(self)
  end

  def to_lilypond(**options)
    HeadMusic::Notation::LilyPond.render(self, **options)
  end

  def to_h
    {
      "schema_version" => SCHEMA_VERSION,
      "name" => name,
      "composer" => composer&.to_s,
      "origin" => origin&.to_s,
      "timeline" => timeline_to_h,
      "parts" => parts.map(&:to_h),
      "bars" => bars_to_h,
      "comments" => comments.map(&:to_h)
    }
  end

  # Both fields of a key signature event, always: the signature is what is
  # printed at the clef, and the tonal context is the interpretation, and
  # neither derives the other.
  def timeline_to_h
    {
      "meter" => meter.to_s,
      "key_signature" => key_signature.name,
      "tempo" => tempo_to_h(tempo),
      "meter_changes" => timeline.meter_changes.map { |bar_number, value| {"number" => bar_number, "meter" => value.to_s} },
      "key_signature_changes" => timeline.key_signature_changes.map { |bar_number, event|
        {"number" => bar_number, "signature" => event.signature, "tonal_context" => event.tonal_context&.name}
      },
      "tempo_changes" => timeline.tempo_changes.map { |bar_number, value| {"number" => bar_number, "tempo" => tempo_to_h(value)} }
    }
  end

  def to_json(*_args)
    to_h.to_json
  end

  private

  # Bars can be allocated below the voices' earliest bar (e.g. a key or meter
  # change in a pickup bar), so the earliest bar reflects those allocations too.
  def first_allocated_bar_number
    (@bars || []).index { |bar| !bar.nil? }
  end

  def ensure_attributes(name, key_signature, meter, tempo)
    @name = name || "Composition"
    @timeline = Timeline.new(key_signature: key_signature, meter: meter, tempo: tempo)
  end

  # Two fields rather than a "quarter = 72" string, so that a fractional
  # tempo survives: Tempo.get reads the number by stripping non-digits.
  def tempo_to_h(tempo)
    {"beat_value" => tempo.beat_value.to_s, "beats_per_minute" => tempo.beats_per_minute}
  end

  # Iterates the raw sparse array (not the public #bars slice, which loses the
  # number offset), pairing each non-default bar with its number. Key and meter
  # changes are the timeline's now, so a bar serializes its repeat structure
  # and nothing else.
  def bars_to_h
    (@bars || []).each_with_index.filter_map do |bar, number|
      next if bar.nil?

      bar_hash = bar.to_h
      next if bar_hash.empty?

      {"number" => number}.merge(bar_hash)
    end
  end
end
