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

  def pitches
    [first_pitch, second_pitch]
  end

  def first_pitch
    @first_pitch ||= first_note.pitch
  end

  def second_pitch
    @second_pitch ||= second_note.pitch
  end

  def to_s
    [direction, functional_interval].join(' ')
  end

  def ascending?
    direction == :ascending
  end

  def descending?
    direction == :descending
  end

  def moving?
    ascending? || descending?
  end

  def direction
    @direction ||=
      if first_pitch < second_pitch
        :ascending
      elsif first_pitch > second_pitch
        :descending
      else
        :none
      end
  end

  def method_missing(method_name, *args, &block)
    functional_interval.send(method_name, *args, &block)
  end
end
