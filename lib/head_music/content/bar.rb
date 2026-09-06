# A module for musical content
module HeadMusic::Content; end

# Representation of a bar in a flow
# Encapsulates meter and key signature changes
# and repeat structure (repeat barlines and volta brackets) as content semantics
class HeadMusic::Content::Bar
  attr_reader :flow, :number, :ends_repeat_after_num_plays, :plays_on_passes
  attr_writer :starts_repeat

  def initialize(flow, number: HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
    @flow = flow
    @number = number
    @starts_repeat = false
    @ends_repeat_after_num_plays = nil
    @plays_on_passes = nil
  end

  # The key signature and meter a bar reports are the changes authored here,
  # read from the flow's timeline rather than stored -- nil where nothing was
  # authored, which is what a writer reads to decide whether to print one.
  def key_signature
    flow.timeline.key_signature_change_at(number)&.key_signature
  end

  def meter
    flow.timeline.meter_change_at(number)
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
  #
  # Key and meter changes are not here: they belong to the flow's timeline, and
  # a bar merely reports the ones authored in it.
  def to_h
    hash = {}
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
