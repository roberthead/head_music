# A module for musical analysis
module HeadMusic::Analysis; end

# Spells key numbers on the line of fifths around a key's center, after
# Temperley, The Cognition of Basic Musical Structures (2001), and Meredith,
# "The ps13 pitch spelling algorithm," Journal of New Music Research 35 (2006).
class HeadMusic::Analysis::PitchSpeller
  SpelledNote = Data.define(:note, :pitch, :rule)
  LineOfFifths = HeadMusic::Analysis::LineOfFifths

  attr_reader :input

  def initialize(input, key: :infer, **note_input_options)
    @input = HeadMusic::Analysis::NoteInput.for(input, **note_input_options)
    @regions = regions_for(key).sort_by(&:onset)
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
    when Array then key
    else
      first_bar, onset = input.bar_starts.first
      [HeadMusic::Analysis::KeyRegion.new(bar_number: first_bar, onset: onset, key: tonal_context(key))]
    end
  end

  # The seam for KeyFinder#regions.
  def inferred_regions
    raise NotImplementedError, "key inference is not yet available; pass key:"
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
    return HeadMusic::Rudiment::Mode.get(name) if HeadMusic::Rudiment::Mode::MODES.include?(qualifier)

    HeadMusic::Rudiment::Key.get(name)
  end

  def spell
    @indices = Array.new(notes.length)
    @rules = Array.new(notes.length)
    notes.each_with_index { |note, position| classify(note, position) }
    notes.each_with_index.map { |note, position| spelled_note(note, position) }
  end

  def classify(note, position)
    rule, choice = key_center_at(note.onset).choice(note.number % 12)
    if rule == :near
      decide(position, choice.first, :center)
    else
      decide(position, choice, rule)
    end
  end

  def decide(position, index, rule)
    @indices[position] = index
    @rules[position] = rule
  end

  def key_center_at(onset)
    following = @regions.bsearch_index { |region| region.onset > onset }
    region = @regions[[(following || @regions.length) - 1, 0].max]
    @key_centers[region.key] ||= KeyCenter.for(region.key)
  end

  def spelled_note(note, position)
    pitch = LineOfFifths.pitch_at(note.number, @indices[position])
    return SpelledNote.new(note: note, pitch: pitch, rule: @rules[position]) if pitch

    SpelledNote.new(note: note, pitch: HeadMusic::Rudiment::Pitch.from_number(note.number), rule: :fallback)
  end
end
