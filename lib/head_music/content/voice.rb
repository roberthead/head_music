# frozen_string_literal: true

# A Voice is a stream of music with some indepedence that is conceptually one part or for one performer.
# The melodic lines in counterpoint are each a voice.
class HeadMusic::Voice
  include Comparable

  attr_reader :composition, :placements, :role

  delegate :key_signature, to: :composition

  def initialize(composition: nil, role: nil)
    @composition = composition || HeadMusic::Composition.new
    @role = role
    @placements = []
  end

  def place(position, rhythmic_value, pitch = nil)
    HeadMusic::Placement.new(self, position, rhythmic_value, pitch).tap do |placement|
      insert_into_placements(placement)
    end
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
    pitches.max
  end

  def lowest_pitch
    pitches.min
  end

  def highest_notes
    notes.select { |note| note.pitch == highest_pitch }
  end

  def lowest_notes
    notes.select { |note| note.pitch == lowest_pitch }
  end

  def range
    HeadMusic::DiatonicInterval.new(lowest_pitch, highest_pitch)
  end

  def melodic_intervals
    @melodic_intervals ||=
      notes.each_cons(2).map { |note_pair| HeadMusic::MelodicInterval.new(*note_pair) }
  end

  def leaps
    melodic_intervals.select(&:leap?)
  end

  def large_leaps
    melodic_intervals.select(&:large_leap?)
  end

  def cantus_firmus?
    role.to_s =~ /cantus.?firmus/i
  end

  def note_at(position)
    notes.detect { |note| position.within_placement?(note) }
  end

  def notes_during(placement)
    notes.select { |note| note.during?(placement) }
  end

  def note_preceding(position)
    notes.select { |note| note.position < position }.last
  end

  def note_following(position)
    notes.detect { |note| note.position > position }
  end

  def earliest_bar_number
    return 1 if notes.empty?

    placements.first.position.bar_number
  end

  def latest_bar_number
    return 1 if notes.empty?

    placements.last.position.bar_number
  end

  def to_s
    "#{role}: #{pitches.first(10).map(&:to_s)}"
  end

  private

  def insert_into_placements(placement)
    @placements << placement
    @placements = @placements.sort
  end
end
