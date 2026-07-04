# A module for musical content
module HeadMusic::Content; end

# Representation of a bar in a composition
# Encapsulates meter and key signature changes
# and repeat structure (repeat barlines and volta brackets) as content semantics
class HeadMusic::Content::Bar
  attr_reader :composition, :ends_repeat_after_num_plays, :plays_on_passes
  attr_accessor :key_signature, :meter
  attr_writer :starts_repeat

  def initialize(composition, key_signature: nil, meter: nil)
    @composition = composition
    @key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature) if key_signature
    @meter = HeadMusic::Rudiment::Meter.get(meter) if meter
    @starts_repeat = false
    @ends_repeat_after_num_plays = nil
    @plays_on_passes = nil
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
