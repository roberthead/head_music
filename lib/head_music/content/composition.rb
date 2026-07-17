# A module for musical content
module HeadMusic::Content; end

# A composition is musical content.
class HeadMusic::Content::Composition
  SCHEMA_VERSION = 1

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

  # Rebuilds a composition from a schema v1 hash by replaying the public
  # builder API in dependency order: meter and key changes first (position
  # strings roll counts and ticks over via the meter map), then placements,
  # then repeat flags (a pickup-bar flag needs its bar allocated), then
  # comments. Validates values at the boundary so corrupted input raises
  # ArgumentError with path context instead of silently deserializing wrong.
  class HashDeserializer
    def initialize(hash)
      raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

      @hash = hash.deep_transform_keys(&:to_s)
      validate_schema_version
    end

    def composition
      @composition ||= build_base_composition.tap do |composition|
        apply_bar_changes(composition)
        build_voices(composition)
        apply_repeat_flags(composition)
        add_comments(composition)
      end
    end

    private

    attr_reader :hash

    def validate_schema_version
      version = hash["schema_version"]
      return if version.is_a?(Integer) && version == SCHEMA_VERSION

      raise ArgumentError, "unsupported schema_version: #{version.inspect} (supported: #{SCHEMA_VERSION})"
    end

    def build_base_composition
      HeadMusic::Content::Composition.new(
        name: hash["name"],
        key_signature: parsed_key_signature(hash["key_signature"], "key_signature"),
        meter: parsed_meter(hash["meter"], "meter"),
        composer: hash["composer"],
        origin: hash["origin"]
      )
    end

    def bar_hashes
      @bar_hashes ||= Array(hash["bars"])
    end

    def apply_bar_changes(composition)
      bar_hashes.each_with_index do |bar_hash, index|
        number = validated_bar_number(bar_hash, index)
        path = "bars[#{index}]"
        key_signature = parsed_key_signature(bar_hash["key_signature"], path)
        meter = parsed_meter(bar_hash["meter"], path)
        composition.change_key_signature(number, key_signature) if key_signature
        composition.change_meter(number, meter) if meter
      end
    end

    def build_voices(composition)
      Array(hash["voices"]).each_with_index do |voice_hash, voice_index|
        voice = composition.add_voice(role: voice_hash["role"])
        Array(voice_hash["placements"]).each_with_index do |placement_hash, placement_index|
          path = "voices[#{voice_index}].placements[#{placement_index}]"
          rhythmic_value = parsed_rhythmic_value(placement_hash["rhythmic_value"], path)
          pitch = parsed_pitch(placement_hash["pitch"], path)
          voice.place(placement_hash["position"], rhythmic_value, pitch)
        end
      end
    end

    def apply_repeat_flags(composition)
      bar_hashes.each_with_index do |bar_hash, index|
        next unless repeat_state?(bar_hash)

        bar = composition.bars(validated_bar_number(bar_hash, index)).last
        bar.starts_repeat = true if bar_hash["starts_repeat"]
        bar.ends_repeat_after_num_plays = bar_hash["ends_repeat_after_num_plays"] if bar_hash["ends_repeat_after_num_plays"]
        bar.plays_on_passes = bar_hash["plays_on_passes"] if bar_hash["plays_on_passes"]
      end
    end

    def add_comments(composition)
      Array(hash["comments"]).each do |comment_hash|
        composition.add_comment(comment_hash["text"], comment_hash["position"])
      end
    end

    def repeat_state?(bar_hash)
      bar_hash["starts_repeat"] || bar_hash["ends_repeat_after_num_plays"] || bar_hash["plays_on_passes"]
    end

    def validated_bar_number(bar_hash, index)
      number = bar_hash["number"]
      unless number.is_a?(Integer) && number >= 0
        raise ArgumentError, "bars[#{index}]: bar number must be an Integer of at least 0, got #{number.inspect}"
      end
      number
    end

    def parsed_key_signature(value, path)
      return nil if value.nil?

      key_signature = begin
        HeadMusic::Rudiment::KeySignature.get(value)
      rescue
        nil
      end
      raise ArgumentError, "#{path}: unknown key signature #{value.inspect}" unless key_signature

      key_signature
    end

    def parsed_meter(value, path)
      return nil if value.nil?

      meter = begin
        HeadMusic::Rudiment::Meter.get(value)
      rescue
        nil
      end
      unless meter&.top_number&.positive? && meter.bottom_number.positive?
        raise ArgumentError, "#{path}: unknown meter #{value.inspect}"
      end
      meter
    end

    def parsed_rhythmic_value(value, path)
      rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(value)
      unless valid_rhythmic_value?(rhythmic_value)
        raise ArgumentError, "#{path}: unknown rhythmic value #{value.inspect}"
      end
      rhythmic_value
    end

    # RhythmicValue.get returns a hollow object (nil unit) for garbage rather
    # than nil, and a tied tail can be hollow while the head parses, so the
    # whole tie chain is checked.
    def valid_rhythmic_value?(rhythmic_value)
      return false unless rhythmic_value.is_a?(HeadMusic::Rudiment::RhythmicValue)
      return false unless rhythmic_value.unit

      rhythmic_value.tied_value.nil? || valid_rhythmic_value?(rhythmic_value.tied_value)
    end

    # A nil pitch is a rest; a non-nil string that fails to parse would
    # otherwise silently deserialize as a rest.
    def parsed_pitch(value, path)
      return nil if value.nil?

      pitch = HeadMusic::Rudiment::Pitch.get(value)
      raise ArgumentError, "#{path}: unknown pitch #{value.inspect}" unless pitch

      pitch
    end
  end
end
