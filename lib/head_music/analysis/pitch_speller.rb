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

  attr_reader :input, :regions

  # A copy of the flow with its pitches respelled. See Respelling.
  def self.respell(flow, key: nil, **finder_options)
    Respelling.new(flow, key: key, **finder_options).flow
  end

  def initialize(input, key: :infer, **options)
    @finder_options = options.slice(*FINDER_OPTIONS)
    raise ArgumentError, "#{@finder_options.keys.join(", ")} apply only to key: :infer" if @finder_options.any? && key != :infer

    @input = HeadMusic::Analysis::NoteInput.for(input, **options.except(*FINDER_OPTIONS))
    @regions = regions_for(key).sort_by(&:onset).freeze
    @spelling_regions = @regions.empty? ? [region_at_first_bar(DEFAULT_KEY)] : @regions
    @key_centers = {}
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

  def regions_for(key)
    case key
    when :infer then inferred_regions
    when Array then key_regions(key)
    else [region_at_first_bar(tonal_context(key))]
    end
  end

  def key_regions(regions)
    raise ArgumentError, "key: needs at least one key region" if regions.empty?

    regions.map do |region|
      raise ArgumentError, "expected a KeyRegion, got #{region.inspect}" unless region.is_a?(HeadMusic::Analysis::KeyRegion)

      region.with(key: tonal_context(region.key))
    end
  end

  def region_at_first_bar(key)
    first_bar, onset = input.bar_starts.first
    HeadMusic::Analysis::KeyRegion.new(bar_number: first_bar, onset: onset, key: key)
  end

  def inferred_regions
    HeadMusic::Analysis::KeyFinder.new(input, **@finder_options).regions
  end

  def tonal_context(key)
    case key
    when HeadMusic::Rudiment::DiatonicContext, HeadMusic::Rudiment::KeySignature then key
    when String, Symbol then named_tonal_context(key.to_s)
    else raise ArgumentError, "expected a key, a mode, or key regions, got #{key.inspect}"
    end
  end

  def named_tonal_context(name)
    qualifier = name.split.last.to_s.downcase.to_sym
    context_class = HeadMusic::Rudiment::Mode::MODES.include?(qualifier) ? HeadMusic::Rudiment::Mode : HeadMusic::Rudiment::Key
    context = context_class.get(name)
    raise ArgumentError, "unknown key #{name.inspect}" unless context.tonic_spelling

    context
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
    rule, choice = key_center_at(note.onset).choice(note.number % 12)
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

  def key_center_at(onset)
    following = @spelling_regions.bsearch_index { |region| region.onset > onset }
    region = @spelling_regions[[(following || @spelling_regions.length) - 1, 0].max]
    @key_centers[region.key] ||= KeyCenter.for(region.key)
  end

  def apply_direction
    following = next_numbers
    @pending.keys.each do |position|
      step = following[position]&.map { |number| number - notes[position].number }&.find { |difference| difference.abs == 1 }
      next unless step

      pair = @pending.delete(position)
      decide(position, step.positive? ? pair.max : pair.min, :direction)
    end
  end

  def next_numbers
    following = {}
    voices.each_value do |positions|
      chords = positions.sort_by { |position| [notes[position].onset, position] }
        .chunk_while { |a, b| notes[a].onset == notes[b].onset }.to_a
      chords.each_cons(2) do |chord, after|
        numbers = after.map { |position| notes[position].number }
        chord.each { |position| following[position] = numbers }
      end
      chords.each { |chord| lead_grace_notes_to_main_notes(chord, following) }
    end
    following
  end

  # A grace note has no duration, at its main note's onset.
  def lead_grace_notes_to_main_notes(chord, following)
    grace_notes, main_notes = chord.partition { |position| notes[position].duration.zero? }
    return if grace_notes.empty? || main_notes.empty?

    numbers = main_notes.map { |position| notes[position].number }
    grace_notes.each { |position| following[position] = numbers }
  end

  # Notes given without voices are one voice where none overlaps another.
  def voices
    voiced = notes.each_index.reject { |position| notes[position].voice.nil? }
    return {nil => notes.each_index.to_a} if voiced.empty? && !overlapping?

    voiced.group_by { |position| notes[position].voice }
  end

  def overlapping?
    finish = nil
    notes.sort_by(&:onset).any? do |note|
      overlaps = finish && note.onset < finish
      finish = [finish, note.onset + note.duration].compact.max
      overlaps
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
    centers = group.map { |position| key_center_at(notes[position].onset).center }
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

  # Sweeps the notes in onset order, answering those sounding at each onset
  # asked for in turn.
  class Sounding
    def initialize(notes)
      @notes = notes
      @order = notes.each_index.sort_by { |position| [notes[position].onset, position] }
      @cursor = 0
      @active = []
    end

    def at(onset)
      while @cursor < @order.length && @notes[@order[@cursor]].onset <= onset
        @active << @order[@cursor]
        @cursor += 1
      end
      @active.select! { |position| @notes[position].onset + @notes[position].duration > onset }
      @active
    end
  end
end
