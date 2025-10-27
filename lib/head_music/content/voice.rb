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

  def place(position, rhythmic_value, pitch = nil)
    HeadMusic::Content::Placement.new(self, position, rhythmic_value, pitch).tap do |placement|
      insert_into_placements(placement)
    end
  end

  def notes
    @placements.select(&:note?).sort_by(&:position)
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

  def melodic_note_pairs
    @melodic_note_pairs ||= notes.each_cons(2).map do |note1, note2|
      HeadMusic::Content::Voice::MelodicNotePair.new(note1, note2)
    end
  end

  def melodic_intervals
    @melodic_intervals ||=
      melodic_note_pairs.map { |note_pair| HeadMusic::Analysis::MelodicInterval.new(*note_pair.notes) }
  end

  def leaps
    melodic_note_pairs.select(&:leap?)
  end

  def large_leaps
    melodic_note_pairs.select(&:large_leap?)
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

  def to_s
    return pitches_string if role.to_s.strip == ""

    [role, pitches_string].join(": ")
  end

  private

  def insert_into_placements(placement)
    @placements << placement
    @placements = @placements.sort
  end

  def pitches_string
    pitches.first(10).map(&:to_s).join(" ")
  end

  class MelodicNotePair
    attr_reader :first_note, :second_note

    delegate(
      :octave?, :unison?,
      :perfect?,
      :step?, :leap?, :large_leap?,
      :ascending?, :descending?, :repetition?,
      :spans?,
      to: :melodic_interval
    )

    def initialize(first_note, second_note)
      @first_note = first_note
      @second_note = second_note
    end

    def notes
      @notes ||= [first_note, second_note]
    end

    def pitches
      @pitches ||= notes.map(&:pitch)
    end

    def melodic_interval
      @melodic_interval ||= HeadMusic::Analysis::MelodicInterval.new(*notes)
    end

    def spells_consonant_triad_with?(other_note_pair)
      return false if step? || other_note_pair.step?

      combined_pitches = (pitches + other_note_pair.pitches).uniq
      return false if combined_pitches.length < 3

      HeadMusic::Analysis::PitchCollection.new(combined_pitches).consonant_triad?
    end
  end
end
