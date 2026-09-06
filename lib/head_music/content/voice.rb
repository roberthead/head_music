# A module for musical content
module HeadMusic::Content; end

# A Voice is a stream of music with some indepedence that is conceptually one part or for one performer.
# The melodic lines in counterpoint are each a voice.
class HeadMusic::Content::Voice
  attr_reader :part, :placements, :role

  delegate :flow, to: :part
  delegate :key_signature, to: :flow

  delegate :pitches, :highest_pitch, :lowest_pitch, :highest_notes, :lowest_notes, :range,
    :note_at, :notes_during, :note_preceding, :note_following,
    :melodic_note_pairs, :melodic_intervals, :leaps, :large_leaps,
    to: :melodic_line

  # A voice is always in a part, always in a flow. Given neither, it mints the
  # chain rather than raising, so that a voice remains the smallest thing a
  # caller can construct and reason about on its own.
  def initialize(part: nil, flow: nil, role: nil)
    @part = part || detached_part(flow)
    @role = role
    @placements = []
    # No stored event for the opening staff: a voice sits on its part's first
    # staff until it says otherwise, and a single-staff part needs no
    # assignments at all.
    @staff_assignment_map = HeadMusic::Time::EventMap.new
    @part.attach(self)
  end

  # @return [HeadMusic::Content::Staff] the staff this voice is written on at
  #   a bar; never nil, because a voice always has its part's first staff
  def staff_at(bar_number)
    @staff_assignment_map.at(downbeat_of(bar_number)) || part.staff_system_at(bar_number).first_staff
  end

  def staff
    staff_at(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
  end

  # Write this voice onto a staff of its own part from a bar onward.
  #
  # A crossing is one event, not a span: a left hand that rises into the
  # treble staff at bar 5 and comes back down at bar 9 is two crossings, each
  # authored where it happens. A single cross-staff note is a crossing and, a
  # bar later, another. There is no note-level special case, and nothing to
  # overlap.
  #
  # @param staff [HeadMusic::Content::Staff] a staff of this part's system
  # @param bar_number [Integer] the first bar on that staff
  def assign_staff(bar_number, staff)
    ensure_staff_in_system!(staff, bar_number)
    @staff_assignment_map.add(downbeat_of(bar_number), staff).value
  end

  # #assign_staff in the order the sentence is spoken: cross to the treble
  # staff from bar 5.
  def cross_to(staff, from:)
    assign_staff(from, staff)
  end

  def staff_assignments
    @staff_assignment_map.events.to_h { |event| [event.position.bar, event.value] }
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
    last_placement ? last_placement.next_position : HeadMusic::Content::Position.new(flow, 1, 1, 0)
  end

  # Returns nil if placements are contiguous, or [expected_position, found_placement]
  # for the first gap.
  def first_gap
    Continuity.new(flow, placements).first_gap
  end

  def to_s
    return pitches_string if role.to_s.strip == ""

    [role, pitches_string].join(": ")
  end

  def to_h
    hash = {"role" => role&.to_s, "placements" => placements.map(&:to_h)}
    assignments = staff_assignments_to_h
    hash["staff_assignments"] = assignments unless assignments.empty?
    hash
  end

  private

  # Serialized by index within the part's system at that bar, because a staff
  # has no identity of its own -- two five-line treble staves are the same
  # description of different staves.
  def staff_assignments_to_h
    staff_assignments.filter_map do |bar_number, staff|
      index = part.staff_system_at(bar_number).staves.index { |candidate| candidate.equal?(staff) }
      {"number" => bar_number, "staff" => index} if index
    end
  end

  # A voice may only be written on a staff its part actually has. Crossing to
  # someone else's staff is a cue, which is a layout concern, not this.
  def ensure_staff_in_system!(staff, bar_number)
    return if part.staff_system_at(bar_number).include?(staff)

    raise ArgumentError, "the staff is not in the part's staff system at bar #{bar_number}"
  end

  def downbeat_of(bar_number)
    HeadMusic::Time::MusicalPosition.new(bar_number, HeadMusic::Time::MusicalPosition::FIRST_COUNT, 0, 0)
  end

  # A part in the given flow, or in a flow of its own. Not registered with the
  # flow: a voice constructed directly has never appeared in its flow's
  # voices, and preserving that is what keeps the harmony guides seeing the
  # same companions they saw before.
  def detached_part(flow)
    HeadMusic::Content::Part.new(flow: flow || HeadMusic::Content::Flow.new)
  end

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
