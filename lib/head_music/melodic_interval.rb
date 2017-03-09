class HeadMusic::MelodicInterval
  attr_reader :voice, :first_note, :second_note

  def initialize(voice, note1, note2)
    @voice = voice
    @first_note = note1
    @second_note = note2
  end

  def functional_interval
    @functional_interval ||= HeadMusic::FunctionalInterval.new(first_note, second_note)
  end

  def method_missing(method_name, *args, &block)
    functional_interval.send(method_name, *args, &block)
  end
end
