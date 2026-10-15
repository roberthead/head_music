# A module for musical content
module HeadMusic::Content; end

# A voice event is a note, chord, or rest at a position within a voice in a
# flow. Each one fills time, so a voice's events run end to end. It is
# abstract: a NoteEvent sounds and a RestEvent is silent, and .build answers
# whichever the sounds call for.
class HeadMusic::Content::VoiceEvent
  include Comparable

  attr_reader :voice, :position, :rhythmic_value

  # Authored beam grouping relative to the previous voice event, set after
  # construction (the Bar-style side-metadata pattern). Tri-state: nil = use
  # the meter-derived default, true = force a beam break before this event,
  # false = force a beam join to the previous event. Consumed by the
  # MusicXML writer, which prefers it over the default grouping.
  attr_accessor :beam_break_before

  delegate :flow, to: :voice
  delegate :spelling, to: :pitch, allow_nil: true

  private_class_method :new

  def self.build(voice, position, rhythmic_value, sound_or_sounds = nil)
    sounds = HeadMusic::Content::SoundResolver.resolve(sound_or_sounds)
    return HeadMusic::Content::RestEvent.new(voice, position, rhythmic_value) if sounds.empty?

    HeadMusic::Content::NoteEvent.new(voice, position, rhythmic_value, sounds)
  end

  def initialize(voice, position, rhythmic_value)
    @voice = voice
    ensure_position(position)
    @rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(rhythmic_value)
  end

  def sounds
    []
  end

  def pitches
    sounds.select(&:pitched?)
  end

  # Authored sung text: at most one Syllable per verse, keyed by verse number.
  # Only a NoteEvent sings; the rest have none.
  def syllables
    {}
  end

  def syllable(verse = 1)
    syllables[verse]
  end

  def sung?
    syllables.any?
  end

  # Markings written on the event. Only a NoteEvent carries them; the rest
  # have none, so readers and writers need not ask which kind they hold.
  def articulations
    []
  end

  def ornaments
    []
  end

  def note_dynamic
    nil
  end

  # The grace notes sounding before the event, in order. Only a NoteEvent
  # carries them.
  def grace_notes
    []
  end

  # The top pitch of a chord (or the only pitch of a note), which melodic
  # analysis treats as the melody note. Returns nil for rests and
  # unpitched-only events; pitched? is the guard. Enharmonic ties
  # resolve to the first-listed pitch (MRI's max keeps the earliest of
  # equals; a spec pins the behavior).
  def pitch
    pitches.max
  end

  def rest?
    false
  end

  def sounded?
    sounds.any?
  end

  def note?
    sounds.length == 1
  end

  def pitched_note?
    note? && pitched?
  end

  def unpitched_note?
    note? && !pitched?
  end

  def chord?
    pitches.length > 1
  end

  def pitched?
    sounds.any?(&:pitched?)
  end

  # Rounds the exact end to the nearest subtick, carrying the exact onset's
  # remainder, so that a run of a rounding ratio never drifts.
  def next_position
    memoized[:next_position] ||= position.advance(subticks: (onset_remainder + rhythmic_value.exact_subticks).round)
  end

  # The exact onset less the position, in Rational subticks. Ratios such as
  # 7:4 do not land on whole subticks, so a run of them rounds each onset to
  # the nearest one, measured from the run's start. A run continues while
  # each event begins where the one before ends and the links that meet
  # there share a ratio. Tuplet groups do not break a run, so bracketing
  # never moves an onset.
  def onset_remainder
    memoized[:onset_remainder] ||= Run.new(self).remainder
  end

  def <=>(other)
    position <=> other.position
  end

  def during?(other_event)
    starts_during?(other_event) || ends_during?(other_event) || wraps?(other_event)
  end

  def to_s
    "#{rhythmic_value} #{sounds.any? ? sounds.map { |sound| sound_label(sound) }.join(" ") : "rest"} at #{position}"
  end

  def inspect
    "#<#{self.class.name} #{self}>"
  end

  def to_h
    hash = {
      "position" => position.to_s,
      "rhythmic_value" => rhythmic_value.to_s,
      "sounds" => sounds.map { |sound| HeadMusic::Content::SoundResolver.datum(sound) }
    }
    hash["beam_break_before"] = beam_break_before unless beam_break_before.nil?
    hash["syllables"] = syllables.keys.sort.map { |verse| syllables[verse].to_h } unless syllables.empty?
    hash["articulations"] = articulations.map(&:name_key) unless articulations.empty?
    hash["ornaments"] = ornaments.map(&:name_key) unless ornaments.empty?
    hash["note_dynamic"] = note_dynamic.name_key if note_dynamic
    hash["grace_notes"] = grace_notes.map(&:to_h) unless grace_notes.empty?
    hash
  end

  # @api private for Run, which walks back to the start of a run
  def memoized
    revision = voice.revision
    @memoized = {} unless @memoized_revision == revision
    @memoized_revision = revision
    @memoized
  end

  # Walks back from a voice event to where its run of one ratio starts, or to
  # one whose remainder is already known, then forward adding exact lengths.
  # Iterative, so that a long run cannot exhaust the stack.
  class Run
    def initialize(voice_event)
      @voice_event = voice_event
    end

    def remainder
      events = candidates
      remainder = events.first.memoized[:onset_remainder] || 0
      events.each_cons(2) do |previous, current|
        remainder = current.memoized[:onset_remainder] = following_remainder(previous, remainder, current)
      end
      remainder
    end

    private

    attr_reader :voice_event

    def candidates
      events = [voice_event]
      loop do
        previous = sharing_predecessor(events.first)
        break unless previous

        events.unshift(previous)
        break if previous.memoized.key?(:onset_remainder)
      end
      events
    end

    def following_remainder(previous, remainder, current)
      carried = remainder + previous.rhythmic_value.exact_subticks
      return 0 unless previous.position.advance(subticks: carried.round) == current.position

      carried - carried.round
    end

    def sharing_predecessor(current)
      ratio = current.rhythmic_value.tuplet_ratio
      return unless ratio

      previous = current.voice.voice_event_preceding(current.position)
      previous if previous && previous.rhythmic_value.tied_chain.last.tuplet_ratio == ratio
    end
  end

  private

  def ensure_same_rhythmic_value!(other)
    return if rhythmic_value == other.rhythmic_value

    raise ArgumentError,
      "cannot place a #{other.rhythmic_value} at #{position}: position occupied by a #{rhythmic_value}"
  end

  # Unpitched names may be multi-word, so they are bracketed to keep the
  # space-delimited sound list unambiguous.
  def sound_label(sound)
    sound.pitched? ? sound.to_s : "[#{sound}]"
  end

  def starts_during?(other_event)
    position >= other_event.position && position < other_event.next_position
  end

  def ends_during?(other_event)
    next_position > other_event.position && next_position <= other_event.next_position
  end

  def wraps?(other_event)
    position <= other_event.position && next_position >= other_event.next_position
  end

  def ensure_position(position)
    @position = if position.is_a?(HeadMusic::Content::Position)
      position
    else
      HeadMusic::Content::Position.new(flow, position)
    end
  end
end
