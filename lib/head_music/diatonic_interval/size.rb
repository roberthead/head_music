# Encapsulate the distance methods of the interval
class HeadMusic::DiatonicInterval::Size
  attr_reader :low_pitch, :high_pitch

  def initialize(pitch1, pitch2)
    @low_pitch, @high_pitch = *[pitch1, pitch2].sort
  end

  def number
    @number ||= @low_pitch.steps_to(@high_pitch) + 1
  end

  def simple_number
    @simple_number ||= octave_equivalent? ? 8 : (number - 1) % 7 + 1
  end

  def octaves
    @octaves ||= number / 8
  end

  def simple?
    number <= 8
  end

  def compound?
    !simple?
  end

  def simple_semitones
    @simple_semitones ||= semitones % 12
  end

  def semitones
    (high_pitch - low_pitch).to_i
  end

  def steps
    number - 1
  end

  def simple_steps
    steps % 7
  end

  private

  def octave_equivalent?
    number > 1 && ((number - 1) % 7).zero?
  end
end
