# A module for musical analysis
module HeadMusic::Analysis; end

# Spells key numbers on the line of fifths around a key's center, after
# Temperley, The Cognition of Basic Musical Structures (2001), and Meredith,
# "The ps13 pitch spelling algorithm," Journal of New Music Research 35 (2006).
#
# With key: :infer, the default, the key regions are KeyFinder#regions, which
# take the key finder's options. Where the key finder finds none, as when no
# note lasts, the notes are spelled in C major.
class HeadMusic::Analysis::PitchSpeller
  SpelledNote = Data.define(:note, :pitch, :rule)
  LineOfFifths = HeadMusic::Analysis::LineOfFifths
  FINDER_OPTIONS = %i[profile change_penalty window].freeze
  DEFAULT_KEY = HeadMusic::Rudiment::Key.get("C major")

  attr_reader :input

  # A copy of the flow with its pitches respelled. See Respelling.
  def self.respell(flow, key: nil, **finder_options)
    Respelling.new(flow, key: key, **finder_options).flow
  end

  def initialize(input, key: :infer, **options)
    @input = HeadMusic::Analysis::NoteInput.for(input, **options.except(*FINDER_OPTIONS))
    @key_centers = KeyCenters.new(@input, key: key, **options.slice(*FINDER_OPTIONS))
  end

  def regions
    @key_centers.regions
  end

  def pitches
    spelled_notes.map(&:pitch)
  end

  def spelled_notes
    @spelled_notes ||= spell.freeze
  end

  private

  def notes
    input.notes
  end

  def spell
    @indices = Array.new(notes.length)
    @rules = Array.new(notes.length)
    @pending = {}
    notes.each_with_index { |note, position| classify(note, position) }
    apply_direction
    apply_sonority
    notes.each_with_index.map { |note, position| spelled_note(note, position) }
  end

  def classify(note, position)
    rule, choice = @key_centers.at(note.onset).choice(note.number % 12)
    if rule == :near
      @pending[position] = choice
    else
      decide(position, choice, rule)
    end
  end

  def decide(position, index, rule)
    @indices[position] = index
    @rules[position] = rule
  end

  def apply_direction
    successors = Successors.new(notes)
    @pending.keys.each do |position|
      step = successors.semitone_step(position)
      next unless step

      pair = @pending.delete(position)
      decide(position, step.positive? ? pair.max : pair.min, :direction)
    end
  end

  def apply_sonority
    return if @pending.empty?

    sounding = Sounding.new(notes)
    @pending.keys.group_by { |position| notes[position].onset }.sort_by(&:first).each do |onset, group|
      fixed = sounding.at(onset).reject { |position| @pending.key?(position) }.map { |position| @indices[position] }
      settle(group, fixed)
    end
  end

  def settle(group, fixed)
    centers = group.map { |position| @key_centers.at(notes[position].onset).center }
    choices = Compactness.new(group.map { |position| @pending.fetch(position) }, centers, fixed).choices
    group.zip(choices).each do |position, (index, rule)|
      @pending.delete(position)
      decide(position, index, rule)
    end
  end

  def spelled_note(note, position)
    index = @indices[position]
    pitch = LineOfFifths.pitch_for(note.number, index)
    rule = (pitch.spelling == LineOfFifths.spelling_at(index)) ? @rules[position] : :fallback
    SpelledNote.new(note: note, pitch: pitch, rule: rule)
  end
end
