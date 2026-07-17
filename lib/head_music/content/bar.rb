# A module for musical content
module HeadMusic::Content; end

# Representation of a bar in a composition
# Encapsulates meter and key signature changes
# and repeat structure (repeat barlines and volta brackets) as content semantics
class HeadMusic::Content::Bar
  attr_reader :composition, :ends_repeat_after_num_plays, :plays_on_passes, :key_signature, :meter
  attr_writer :starts_repeat

  def initialize(composition, key_signature: nil, meter: nil)
    @composition = composition
    self.key_signature = key_signature
    self.meter = meter
    @starts_repeat = false
    @ends_repeat_after_num_plays = nil
    @plays_on_passes = nil
  end

  def key_signature=(value)
    @key_signature = value ? HeadMusic::Rudiment::KeySignature.get(value) : nil
  end

  def meter=(value)
    @meter = value ? HeadMusic::Rudiment::Meter.get(value) : nil
  end

  def starts_repeat?
    @starts_repeat
  end

  def ends_repeat_after_num_plays=(value)
    unless valid_ends_repeat_after_num_plays?(value)
      raise ArgumentError, "ends_repeat_after_num_plays must be nil or an integer of at least 2"
    end
    @ends_repeat_after_num_plays = value
  end

  def ends_repeat?
    !ends_repeat_after_num_plays.nil?
  end

  def plays_on_passes=(value)
    unless valid_plays_on_passes?(value)
      raise ArgumentError, "plays_on_passes must be nil or a non-empty array of unique positive integers"
    end
    @plays_on_passes = value
  end

  def plays_on_pass?(pass_number)
    plays_on_passes.nil? || plays_on_passes.include?(pass_number)
  end

  def to_s
    ["Bar", key_signature, meter, repeat_summary].compact.join(" ")
  end

  # Sparse serialization: only non-default state, so a default bar is {}.
  # KeySignature serializes via #name ("F♯ minor") because #to_s ("3 sharps")
  # cannot be parsed back by KeySignature.get.
  def to_h
    hash = {}
    hash["key_signature"] = key_signature.name if key_signature
    hash["meter"] = meter.to_s if meter
    hash["starts_repeat"] = true if starts_repeat?
    hash["ends_repeat_after_num_plays"] = ends_repeat_after_num_plays if ends_repeat?
    hash["plays_on_passes"] = plays_on_passes.dup if plays_on_passes
    hash
  end

  private

  def valid_ends_repeat_after_num_plays?(value)
    return true if value.nil?

    value.is_a?(Integer) && value >= 2
  end

  def valid_plays_on_passes?(value)
    return true if value.nil?

    value.is_a?(Array) && !value.empty? &&
      value.all? { |pass| pass.is_a?(Integer) && pass.positive? } &&
      value.uniq.length == value.length
  end

  def repeat_summary
    parts = []
    parts << "|:" if starts_repeat?
    parts << ":|x#{ends_repeat_after_num_plays}" if ends_repeat?
    parts << "(passes #{plays_on_passes.join(",")})" if plays_on_passes
    parts.join(" ") unless parts.empty?
  end
end
