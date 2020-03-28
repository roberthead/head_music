# frozen_string_literal: true

require 'head_music/interval_cycle'

# A Circle of Fifths or Fourths shows relationships between pitch classes
class HeadMusic::Circle < HeadMusic::IntervalCycle
  def self.of_fifths
    get(:perfect_fifth)
  end

  def self.of_fourths
    get(:perfect_fourth)
  end

  def self.get(interval = :perfect_fifth)
    @circles ||= {}
    diatonic_interval = HeadMusic::DiatonicInterval.get(interval)
    @circles[interval] ||= new(interval: diatonic_interval, starting_pitch: 'C4')
  end

  def index(pitch_class)
    pitch_classes.index(HeadMusic::Spelling.get(pitch_class).pitch_class)
  end

  alias spellings_up spellings

  def key_signatures_up
    spellings_up.map { |spelling| HeadMusic::KeySignature.new(spelling) }
  end

  def key_signatures_down
    spellings_down.map { |spelling| HeadMusic::KeySignature.new(spelling) }
  end

  def spellings_down
    pitches_down.map(&:spelling)
  end

  def pitches_down
    @pitches_down ||= begin
      [starting_pitch].tap do |list|
        loop do
          next_pitch = list.last - interval
          next_pitch += octave while starting_pitch - next_pitch > 12
          break if next_pitch.pitch_class == list.first.pitch_class

          list << next_pitch
        end
      end
    end
  end

  private_class_method :new
end
