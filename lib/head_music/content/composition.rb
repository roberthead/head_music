# A module for musical content
module HeadMusic::Content; end

# A composition is musical content.
class HeadMusic::Content::Composition
  SCHEMA_VERSION = 3

  attr_reader :name, :key_signature, :meter, :voices, :composer, :origin, :comments

  def self.from_h(hash)
    HashDeserializer.new(hash).composition
  end

  def self.from_json(json)
    from_h(JSON.parse(json))
  end

  def initialize(name: nil, key_signature: nil, meter: nil, composer: nil, origin: nil, comments: nil)
    ensure_attributes(name, key_signature, meter)
    @composer = composer
    @origin = origin
    @voices = []
    @comments = Array(comments).map { |text| HeadMusic::Content::Comment.new(self, text) }
  end

  def add_voice(role: nil)
    @voices << HeadMusic::Content::Voice.new(composition: self, role: role)
    @voices.last
  end

  def add_comment(text, position = nil)
    @comments << HeadMusic::Content::Comment.new(self, text, position)
    @comments.last
  end

  def meter_at(bar_number)
    meter_change = last_meter_change(bar_number)
    meter_change ? meter_change.meter : meter
  end

  def key_signature_at(bar_number)
    key_signature_change = last_key_signature_change(bar_number)
    key_signature_change ? key_signature_change.key_signature : key_signature
  end

  def bars(last = latest_bar_number)
    @bars ||= []
    first = [earliest_bar_number, last].min
    (first..last).each do |bar_number|
      @bars[bar_number] ||= HeadMusic::Content::Bar.new(self)
    end
    @bars[first..last]
  end

  def change_key_signature(bar_number, key_signature)
    bars(bar_number).last.key_signature = key_signature
  end

  def change_meter(bar_number, meter)
    bars(bar_number).last.meter = meter
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

  def to_h
    {
      "schema_version" => SCHEMA_VERSION,
      "name" => name,
      "key_signature" => key_signature.name,
      "meter" => meter.to_s,
      "composer" => composer&.to_s,
      "origin" => origin&.to_s,
      "voices" => voices.map(&:to_h),
      "bars" => bars_to_h,
      "comments" => comments.map(&:to_h)
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

  def ensure_attributes(name, key_signature, meter)
    @name = name || "Composition"
    @key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature) if key_signature
    @key_signature ||= HeadMusic::Rudiment::KeySignature.default
    @meter = meter ? HeadMusic::Rudiment::Meter.get(meter) : HeadMusic::Rudiment::Meter.default
  end

  def last_meter_change(bar_number)
    bar_number = [bar_number, earliest_bar_number].max
    bars(bar_number)[earliest_bar_number..bar_number].reverse.detect(&:meter)
  end

  def last_key_signature_change(bar_number)
    bars(bar_number)[earliest_bar_number..bar_number].reverse.detect(&:key_signature)
  end

  # Iterates the raw sparse array (not the public #bars slice, which loses the
  # number offset), pairing each non-default bar with its number.
  def bars_to_h
    (@bars || []).each_with_index.filter_map do |bar, number|
      next if bar.nil?

      bar_hash = bar.to_h
      next if bar_hash.empty?

      {"number" => number}.merge(bar_hash)
    end
  end
end
