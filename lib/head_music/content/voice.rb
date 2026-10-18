# A module for musical content
module HeadMusic::Content; end

# A Voice is a stream of music with some indepedence that is conceptually one part or for one performer.
# The melodic lines in counterpoint are each a voice.
class HeadMusic::Content::Voice
  attr_reader :part, :role

  # @api private bumped whenever a change may move where a voice event ends,
  # so voice events know when their memoized timing is stale
  attr_reader :revision

  delegate :flow, to: :part
  delegate :key_signature, to: :flow

  delegate :pitches, :highest_pitch, :lowest_pitch, :highest_notes, :lowest_notes, :range,
    :note_at, :notes_during, :note_preceding, :note_following,
    :melodic_note_pairs, :melodic_intervals, :leaps, :large_leaps,
    to: :melodic_line

  # The voice event at a position, the first at or after it, and the one
  # sounding at it.
  # The one starting last before a position, too.
  delegate :at, :starting_from, :sounding_at, :preceding, to: :@voice_events, prefix: :voice_event

  # A voice is always in a part, always in a flow. Given neither, it mints the
  # chain rather than raising, so that a voice remains the smallest thing a
  # caller can construct and reason about on its own.
  def initialize(part: nil, flow: nil, role: nil)
    @part = part || detached_part(flow)
    @role = role
    @voice_events = HeadMusic::Content::VoiceEvents.new
    @revision = 0
    @dynamic_events = HeadMusic::Content::DynamicEvents.new(@part.flow)
    @spans = HeadMusic::Content::Spans.new
    @span_anchors = SpanAnchors.new(self)
    @tuplets = HeadMusic::Content::TupletGroups.new
    @staff_assignments = StaffAssignments.new(@part)
    @part.attach(self)
  end

  # Write this voice onto a staff of its own part from a bar onward with
  # assign_staff(bar_number, staff), and ask which staff it is on at a bar with
  # staff_at(bar_number).
  delegate :staff_at, :assign_staff, to: :@staff_assignments

  def staff
    staff_at(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
  end

  # #assign_staff in the order the sentence is spoken: cross to the treble
  # staff from bar 5.
  def cross_to(staff, from:)
    assign_staff(from, staff)
  end

  def staff_assignments
    @staff_assignments.to_h
  end

  def place(position, rhythmic_value, sound_or_sounds = nil)
    # The melodic line is a snapshot of the notes, so placing anything invalidates it.
    @melodic_line = nil
    voice_event = HeadMusic::Content::VoiceEvent.build(self, position, rhythmic_value, sound_or_sounds)
    ensure_outside_tuplets(voice_event)
    # An event's timing depends only on the events before it, so appending
    # leaves every memo good, and reading a voice in order stays linear.
    @revision += 1 if last_voice_event && voice_event.position < last_voice_event.position
    @voice_events.place(voice_event)
  end

  # Brackets the notes and rests from one position up to another as one
  # tuplet. They must already carry its ratio, and fill the span exactly.
  # A bracket moves no onset, so grouping leaves every memoized timing good.
  def group_tuplet(from:, to:, unit: nil)
    @tuplets.add(HeadMusic::Content::TupletGroup.new(self, from: from, to: to, unit: unit))
  end

  def tuplets
    @tuplets.to_a
  end

  # The tuplet group covering a position, or nil.
  def tuplet_at(position)
    @tuplets.at(HeadMusic::Content::Position.get(flow, position))
  end

  # In position order, with at most one at a position.
  def voice_events
    @voice_events.to_a
  end

  # A dynamic level for this voice alone. It takes no time, so it is not a
  # voice event, and it may fall under a held note or a rest.
  def place_dynamic(position, level)
    @dynamic_events.place(position, level)
  end

  def dynamic_events
    @dynamic_events.to_a
  end

  # The dynamic level in force at a position, or nil where nothing has been
  # written. See DynamicResolver for which level wins.
  def dynamic_at(position)
    DynamicResolver.new(self, @dynamic_events).level_at(position)
  end

  # A marking from one point in this voice to a later one, such as a slur or
  # a crescendo. Its kind says what its ends must sit on: a slur needs notes,
  # a phrase may begin or end on a rest, and a hairpin may end anywhere. A
  # curve from_grace starts on the first grace note of the note at from.
  def add_span(kind, from:, to:, from_grace: false)
    span = HeadMusic::Content::Span.new(flow, kind, from: from, to: to, from_grace: from_grace)
    @span_anchors.ensure_anchored(span)
    @spans.add(span)
  end

  def spans
    @spans.to_a
  end

  # The voice's spans in force at a position, with its part's, innermost
  # first. A span that covers its last note runs until that note ends.
  def spans_at(position)
    position = HeadMusic::Content::Position.get(flow, position)
    own = @spans.covering(position) { |span| @span_anchors.end_of(span) }
    HeadMusic::Content::Spans.innermost_first(own + part.spans_at(position))
  end

  # Voice events are kept in position order, so the notes and rests drawn from
  # them are already ordered.
  def notes
    voice_events.select(&:pitched?)
  end

  def note_events
    voice_events.grep(HeadMusic::Content::NoteEvent)
  end

  def rest_events
    voice_events.grep(HeadMusic::Content::RestEvent)
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
    voice_events.first&.bar_number || 1
  end

  def latest_bar_number
    last_voice_event&.bar_number || 1
  end

  def last_voice_event
    voice_events.last
  end

  def next_position
    last_voice_event ? last_voice_event.next_position : HeadMusic::Content::Position.new(flow, 1, 1, 0)
  end

  # Returns nil if voice events are contiguous, or [expected_position, found_voice_event]
  # for the first gap.
  def first_gap
    Continuity.new(flow, voice_events).first_gap
  end

  def to_s
    role.to_s.strip.empty? ? pitches_string : "#{role}: #{pitches_string}"
  end

  def inspect
    "#<#{self.class.name} #{self}>"
  end

  def to_h
    optional = {
      "staff_assignments" => @staff_assignments.to_a,
      "dynamic_events" => dynamic_events.map(&:to_h),
      "spans" => spans.map(&:to_h),
      "tuplets" => tuplets.map(&:to_h)
    }
    {"role" => role&.to_s, "voice_events" => voice_events.map(&:to_h)}.merge(optional.reject { |_key, value| value.empty? })
  end

  private

  # A part in the given flow, or in a flow of its own. Not registered with the
  # flow: a voice constructed directly has never appeared in its flow's
  # voices, and preserving that is what keeps the harmony guides seeing the
  # same companions they saw before.
  def detached_part(flow)
    HeadMusic::Content::Part.new(flow: flow || HeadMusic::Content::Flow.new)
  end

  # A note placed onto one already there merges with it, which keeps the
  # group whole; any other placement inside a group would break it.
  def ensure_outside_tuplets(voice_event)
    position = voice_event.position
    return if @tuplets.empty? || voice_event_at(position)

    group = @tuplets.at(position)
    return unless group

    raise ArgumentError, "cannot place a #{voice_event.rhythmic_value} at #{position} inside the #{group}"
  end

  def pitches_string
    pitches.first(10).join(" ")
  end
end
