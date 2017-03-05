class HeadMusic::Style::Annotation
  attr_reader :start_position, :end_position, :message

  # Note: message should be a directive.
  # For example:
  #   "Reduce frequency of skips"
  #   "Make strong beats consonant"
  #   "Use the notes in the key signature"

  delegate :composition, to: :voice

  def initialize(voice, start_position, end_position, message)
    @voice = voice
    @start_position = start_position
    @end_position = end_position
    @message = message
  end

  def range_string
    [start_position.code, end_position.code].join(' to ')
  end

  def description
    [range_string, message].join(': ')
  end

  alias_method :to_s, :description
end
