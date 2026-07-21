# A module for musical content
module HeadMusic::Content; end

# A Voice is a stream of music with some indepedence that is conceptually one part or for one performer.
# The melodic lines in counterpoint are each a voice.
class HeadMusic::Content::Voice
  include Comparable

  attr_reader :composition, :placements, :role

  delegate :key_signature, to: :composition

  def initialize(composition: nil, role: nil)
    @composition = composition || HeadMusic::Content::Composition.new
    @role = role
    @placements = []
  end

  def place(position, rhythmic_value, sound_or_sounds = nil)
    placement = HeadMusic::Content::Placement.new(self, position, rhythmic_value, sound_or_sounds)
    existing = placement_at(placement.position)
    return existing.merge(placement) if existing

    insert_into_placements(placement)
    placement
  end

  def notes
    @placements.select(&:pitched?).sort_by(&:position)
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
    HeadMusic::Analysis::DiatonicInterval.new(lowest_pitch, highest_pitch)
  end

  def melodic_line
    @melodic_line ||= MelodicLine.new(notes)
  end

  delegate :melodic_note_pairs, :melodic_intervals, :leaps, :large_leaps, to: :melodic_line

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
    notes.reverse.find { |note| note.position < position }
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

  def last_placement
    placements.last
  end

  def next_position
    last_placement ? last_placement.next_position : HeadMusic::Content::Position.new(composition, 1, 1, 0)
  end

  # Returns nil if placements are contiguous, or [expected_position, found_placement]
  # for the first gap: either the first placement not starting its bar, or the
  # first pair of consecutive placements where the second doesn't begin where
  # the first one ends.
  def first_gap
    first = placements.first
    return unless first

    first_position = first.position
    return [bar_start_position(first), first] unless first_position.count == 1 && first_position.tick.zero?

    placements.each_cons(2) do |previous, current|
      expected_position = previous.next_position
      return [expected_position, current] unless current.position == expected_position
    end
    nil
  end

  def to_s
    return pitches_string if role.to_s.strip == ""

    [role, pitches_string].join(": ")
  end

  def to_h
    {
      "role" => role&.to_s,
      "placements" => placements.map(&:to_h)
    }
  end

  private

  def bar_start_position(placement)
    HeadMusic::Content::Position.new(composition, placement.position.bar_number, 1, 0)
  end

  def placement_at(position)
    @placements.find { |placement| placement.position == position }
  end

  # Positions are unique within a voice (place merges same-position
  # placements), so insertion order is simply position order.
  def insert_into_placements(placement)
    index = @placements.index { |existing| existing > placement } || @placements.length
    @placements.insert(index, placement)
  end

  def pitches_string
    pitches.first(10).join(" ")
  end
end
