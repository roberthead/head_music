require "head_music/analysis/interval_cycle"

# A module for musical analysis
module HeadMusic::Analysis; end

# A Circle of Fifths or Fourths shows relationships between pitch classes
class HeadMusic::Analysis::Circle < HeadMusic::Analysis::IntervalCycle
  def self.of_fifths
    get(:perfect_fifth)
  end

  def self.of_fourths
    get(:perfect_fourth)
  end

  def self.get(interval = :perfect_fifth)
    @circles ||= {}
    diatonic_interval = HeadMusic::Analysis::DiatonicInterval.get(interval)
    @circles[interval] ||= new(interval: diatonic_interval, starting_pitch: "C4")
  end

  def index(pitch_class)
    pitch_classes.index(HeadMusic::Rudiment::Spelling.get(pitch_class).pitch_class)
  end

  def key_signatures_up
    spellings_up.map { |spelling| HeadMusic::Rudiment::KeySignature.new(spelling) }
  end

  def key_signatures_down
    spellings_down.map { |spelling| HeadMusic::Rudiment::KeySignature.new(spelling) }
  end

  def spellings_up
    pitches_up.map(&:pitch_class).map do |pitch_class|
      pitch_class.smart_spelling(max_sharps_in_major_key_signature: 7)
    end
  end

  def spellings_down
    pitches_down.map(&:pitch_class).map do |pitch_class|
      pitch_class.smart_spelling(max_sharps_in_major_key_signature: 4)
    end
  end

  def pitches_down
    @pitches_down ||= [starting_pitch].tap do |list|
      loop do
        next_pitch = list.last - interval
        next_pitch += octave while starting_pitch - next_pitch > 12
        break if next_pitch.pitch_class == list.first.pitch_class

        list << next_pitch
      end
    end
  end

  private_class_method :new
end
