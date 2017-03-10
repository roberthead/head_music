class HeadMusic::MelodicInterval
  attr_reader :voice, :first_note, :second_note

  def initialize(voice, note1, note2)
    @voice = voice
    @first_note = note1
    @second_note = note2
  end

  def functional_interval
    @functional_interval ||= HeadMusic::FunctionalInterval.new(first_note.pitch, second_note.pitch)
  end

  def position_start
    first_note.position
  end

  def position_end
    second_note.next_position
  end

  def notes
    [first_note, second_note]
  end

  def to_s
    [direction, functional_interval].join(' ')
  end

  def method_missing(method_name, *args, &block)
    functional_interval.send(method_name, *args, &block)
  end
end
