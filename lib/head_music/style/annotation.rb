class HeadMusic::Style::Annotation
  attr_reader :fitness, :message, :marks, :subject

  def initialize(subject:, fitness:, message: nil, marks: nil)
    @subject = subject
    @fitness = fitness
    @message = message
    @marks = [marks].flatten.compact
  end

  def voice
    subject if subject.is_a?(HeadMusic::Voice)
  end

  def composition
    voice ? voice.composition : subject
  end

  def marks_count
    marks ? marks.length : 0
  end

  def first_mark_code
    marks.first.code if marks.first
  end

  alias_method :to_s, :message
end
