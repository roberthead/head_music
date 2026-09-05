# A module for musical content
module HeadMusic::Content; end

# A Voice is a stream of music with some indepedence that is conceptually one part or for one performer.
# The melodic lines in counterpoint are each a voice.
class HeadMusic::Content::Voice
  attr_reader :composition, :placements, :role

  delegate :key_signature, to: :composition

  delegate :pitches, :highest_pitch, :lowest_pitch, :highest_notes, :lowest_notes, :range,
    :note_at, :notes_during, :note_preceding, :note_following,
    :melodic_note_pairs, :melodic_intervals, :leaps, :large_leaps,
    to: :melodic_line

  def initialize(composition: nil, role: nil)
    @composition = composition || HeadMusic::Content::Composition.new
    @role = role
    @placements = []
  end

  def place(position, rhythmic_value, sound_or_sounds = nil)
    # The melodic line is a snapshot of the notes, so any placement invalidates it.
    @melodic_line = nil
    placement = HeadMusic::Content::Placement.new(self, position, rhythmic_value, sound_or_sounds)
    existing = placement_at(placement.position)
    return existing.merge(placement) if existing

    insert_into_placements(placement)
    placement
  end

  # Placements are kept in position order, so the notes and rests drawn from
  # them are already ordered.
  def notes
    placements.select(&:pitched?)
  end

  def rests
    placements.select(&:rest?)
  end

  def notes_not_in_key
    key_spellings = key_signature.spellings
    notes.reject { |note| key_spellings.include?(note.pitch.spelling) }
  end

  def melodic_line
    @melodic_line ||= MelodicLine.new(notes)
  end

  def cantus_firmus?
    role.to_s =~ /cantus.?firmus/i
  end

  def earliest_bar_number
    bar_number_of(placements.first)
  end

  def latest_bar_number
    bar_number_of(placements.last)
  end

  def last_placement
    placements.last
  end

  def next_position
    last_placement ? last_placement.next_position : HeadMusic::Content::Position.new(composition, 1, 1, 0)
  end

  # Returns nil if placements are contiguous, or [expected_position, found_placement]
  # for the first gap.
  def first_gap
    Continuity.new(composition, placements).first_gap
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

  def bar_number_of(placement)
    placement ? placement.position.bar_number : 1
  end

  def placement_at(position)
    candidate = placements.bsearch { |placement| placement.position >= position }
    candidate if candidate&.position == position
  end

  # Positions are unique within a voice (place merges same-position
  # placements), so insertion order is simply position order. Both the
  # lookup and the insertion point are binary searches over that order,
  # which keeps placing a long voice linear in its length rather than
  # quadratic.
  def insertion_index(placement)
    placements.bsearch_index { |existing| existing > placement } || placements.length
  end

  def insert_into_placements(placement)
    placements.insert(insertion_index(placement), placement)
  end

  def pitches_string
    pitches.first(10).join(" ")
  end
end
