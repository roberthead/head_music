class HeadMusic::Voice
  include Comparable

  attr_reader :composition, :placements, :role
  delegate :key_signature, to: :composition

  def initialize(composition: nil, role: nil)
    @composition = composition || Composition.new(name: "Composition")
    @role = role
    @placements = []
  end

  def place(position, rhythmic_value, pitch = nil)
    HeadMusic::Placement.new(self, position, rhythmic_value, pitch).tap { |placement|
      insert_into_placements(placement)
    }
  end

  def notes
    @placements.select(&:note?)
  end

  def notes_not_in_key
    key_spellings = key_signature.pitches.map(&:spelling).uniq
    notes.reject { |note| key_spellings.include? note.pitch.spelling }
  end

  def pitches
    notes.map(&:pitch)
  end

  def rests
    @placements.select(&:rest?)
  end

  def highest_pitch
    pitches.sort.last
  end

  def lowest_pitch
    pitches.sort.first
  end

  def highest_notes
    notes.select { |note| note.pitch == highest_pitch }
  end

  def lowest_notes
    notes.select { |note| note.pitch == lowest_pitch }
  end

  def range
    HeadMusic::FunctionalInterval.new(lowest_pitch, highest_pitch)
  end

  def melodic_intervals
    notes.map.with_index do |note, i|
      HeadMusic::MelodicInterval.new(self, notes[i-1], note) if i > 0
    end.reject(&:nil?)
  end

  def leaps
    melodic_intervals.select(&:leap?)
  end

  private

  def insert_into_placements(placement)
    @placements << placement
    @placements = @placements.sort
  end
end
