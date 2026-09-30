# A module for musical content
module HeadMusic::Content; end

# Representation of a bar in a flow
# Encapsulates meter and key signature changes, repeat structure (repeat
# barlines and volta brackets), and the markings that shape how the bars are
# played: barline style, rehearsal mark, and navigation.
#
# A rehearsal mark, segno, coda sign, and repeat start mark the start of the
# bar; its barline, Fine, To Coda, jump, and repeat end mark its end.
class HeadMusic::Content::Bar
  BARLINES = %i[regular double final dashed dotted].freeze
  FLAGS = %i[segno coda fine to_coda].freeze

  attr_reader :flow, :number, :ends_repeat_after_num_plays, :plays_on_passes, :barline, :rehearsal_mark, :jump
  attr_writer :starts_repeat

  def initialize(flow, number: HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
    @flow = flow
    @number = number
    @starts_repeat = false
    @ends_repeat_after_num_plays = nil
    @plays_on_passes = nil
    @barline = :regular
    @rehearsal_mark = nil
    @jump = nil
    FLAGS.each { |flag| instance_variable_set(:"@#{flag}", false) }
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

  def barline=(value)
    style = value.nil? ? :regular : value.to_s.to_sym
    raise ArgumentError, "barline must be one of #{BARLINES.join(", ")}, got #{value.inspect}" unless BARLINES.include?(style)

    @barline = style
  end

  def rehearsal_mark=(value)
    @rehearsal_mark = ensure_rehearsal_mark(value)
  end

  def jump=(value)
    raise ArgumentError, "jump must be nil or a Jump, got #{value.inspect}" unless value.nil? || value.is_a?(HeadMusic::Content::Jump)

    @jump = value
  end

  FLAGS.each do |flag|
    define_method(:"#{flag}?") { instance_variable_get(:"@#{flag}") }

    define_method(:"#{flag}=") do |value|
      raise ArgumentError, "#{flag} must be true or false, got #{value.inspect}" unless [true, false].include?(value)

      instance_variable_set(:"@#{flag}", value)
    end
  end

  def to_s
    ["Bar", key_signature, meter, *marking_summary].compact.join(" ")
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
    hash["barline"] = barline.to_s unless barline == :regular
    hash["rehearsal_mark"] = rehearsal_mark if rehearsal_mark
    FLAGS.each { |flag| hash[flag.to_s] = true if public_send(:"#{flag}?") }
    hash["jump"] = jump.to_h if jump
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

  def ensure_rehearsal_mark(value)
    return if value.nil?
    return value.to_s if value.is_a?(Integer) && value.positive?

    mark = value.strip if value.is_a?(String)
    raise ArgumentError, "rehearsal_mark must be a non-empty String or a positive Integer, got #{value.inspect}" if mark.nil? || mark.empty?

    mark
  end

  def marking_summary
    [
      rehearsal_mark && "[#{rehearsal_mark}]",
      ("segno" if segno?),
      ("coda" if coda?),
      ("|:" if starts_repeat?),
      (":|x#{ends_repeat_after_num_plays}" if ends_repeat?),
      plays_on_passes && "(passes #{plays_on_passes.join(",")})",
      ("Fine" if fine?),
      ("To Coda" if to_coda?),
      jump&.to_s,
      (barline.to_s unless barline == :regular)
    ].compact
  end
end
