# A module for musical content
module HeadMusic::Content; end

# A flow is a continuous span of music with its own timeline: a movement, a
# song, a cue, or a single exercise. Its project is optional, so a flow may
# stand alone; containment below is not: every voice is in a part, and every
# part is in a flow.
class HeadMusic::Content::Flow
  SCHEMA_VERSION = 5
  DEFAULT_NAME = "Composition"

  attr_reader :name, :parts, :origin, :comments, :timeline
  attr_accessor :project

  # The catalog identity this flow is one notation of, and the publication it
  # was taken from. Both optional: a parsed snippet cites neither.
  attr_accessor :work, :source

  delegate :meter_at, :key_signature_at, :tempo_at, to: :timeline
  delegate :meter_changes, :key_signature_changes, :tempo_changes, :meter_change_at, :tempo_change_at, to: :timeline
  delegate :remove_meter_change, :remove_key_signature_change, :remove_tempo_change, to: :timeline

  def self.from_h(hash)
    HashDeserializer.new(hash).flow
  end

  def self.from_json(json)
    from_h(JSON.parse(json))
  end

  def self.from_v4_h(hash)
    from_h(V4Upgrade.flow(hash))
  end

  def initialize(
    name: nil, key_signature: nil, meter: nil, tempo: nil,
    composer: nil, origin: nil, comments: nil, work: nil, source: nil
  )
    ensure_attributes(name, key_signature, meter, tempo)
    @composer = composer
    @origin = origin
    @work = ensure_work(work)
    @source = ensure_source(source)
    @parts = []
    @bars = Bars.new(self)
    @comments = Array(comments).map { |text| HeadMusic::Content::Comment.new(self, text) }
  end

  # The cited work's composer wins over the authored string, which stays as the
  # fallback for the parsed documents that have a name but no work.
  def composer
    work&.composer || @composer
  end

  def voices
    parts.flat_map(&:voices)
  end

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

  def position(code_or_bar, count = nil, tick = nil, subtick = nil)
    HeadMusic::Content::Position.new(self, code_or_bar, count, tick, subtick)
  end

  # The opening signature, meter, and tempo are the timeline's, so a change at
  # bar 1 is a change like any other rather than a rewrite of the flow's own
  # attributes.
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
    @bars.span([earliest_bar_number, last].min, last)
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

  # Bars can be allocated below the voices' earliest bar (e.g. a key or meter
  # change in a pickup bar), so the earliest bar reflects those allocations too.
  def earliest_bar_number
    [*voices.map(&:earliest_bar_number), @bars.first_number, 1].compact.min
  end

  def latest_bar_number
    [*voices.map(&:latest_bar_number), 1].max
  end

  # The bar the music ends in, past the latest bar when the last note is tied
  # across a barline.
  def last_sounding_bar_number
    finish = voices.filter_map { |voice| voice.last_voice_event&.next_position }.max
    return latest_bar_number unless finish

    ending_bar = (finish.to_a.drop(1) == [1, 0, 0]) ? finish.bar_number - 1 : finish.bar_number
    [latest_bar_number, ending_bar].max
  end

  # Allocates only this bar, unlike #bars, which fills in every bar before it.
  def bar(number)
    @bars.span(number, number).first
  end

  # The last bar carrying repeat structure or a marking, which a flow with no
  # voices past it still plays through.
  def last_marked_bar_number
    @bars.last_marked_number
  end

  def performance_order
    PerformanceOrder.new(self).bars
  end

  def cantus_firmus_voice
    voices.detect(&:cantus_firmus?)
  end

  def counterpoint_voice
    voices.reject(&:cantus_firmus?).first
  end

  def to_s
    "#{name} — #{voices.count} #{"voice".pluralize(voices.count)}"
  end

  # The default would print the whole composition, since every voice event
  # reaches its voice and every voice its flow.
  def inspect
    "#<#{self.class.name} #{self}>"
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

  def to_kern(**options)
    HeadMusic::Notation::Kern.render(self, **options)
  end

  def to_h
    {
      "schema_version" => SCHEMA_VERSION,
      "name" => name,
      "composer" => composer&.to_s,
      "origin" => origin&.to_s,
      "work" => work&.to_h,
      "source" => source&.to_h,
      "timeline" => timeline_to_h,
      "parts" => parts_to_h,
      "bars" => @bars.serialize,
      "comments" => comments.map(&:to_h)
    }.merge(part_players_to_h)
  end

  def timeline_to_h
    timeline.to_h
  end

  def to_json(*_args)
    to_h.to_json
  end

  private

  def ensure_work(work)
    return HeadMusic::Content::Work.from_h(work) if work.is_a?(Hash)

    work
  end

  def ensure_source(source)
    return HeadMusic::Content::Publication.from_h(source) if source.is_a?(Hash)

    source
  end

  def ensure_attributes(name, key_signature, meter, tempo)
    @name = name || DEFAULT_NAME
    @timeline = Timeline.new(key_signature: key_signature, meter: meter, tempo: tempo)
  end

  # A player is written once and each part points at it by index, so two parts
  # sharing one chair still share it when read back, and two chairs that happen
  # to share a name stay two. The key is not "players" because a project
  # document already uses that name for its own indexes.
  def part_players
    parts.filter_map(&:player).uniq(&:object_id)
  end

  def part_players_to_h
    players = part_players
    return {} if players.empty?

    {"part_players" => players.map { |player| {"name" => player.name} }}
  end

  def parts_to_h
    players = part_players
    parts.map do |part|
      index = part.player && players.index { |player| player.equal?(part.player) }
      index ? part.to_h.merge("player" => index) : part.to_h
    end
  end
end
