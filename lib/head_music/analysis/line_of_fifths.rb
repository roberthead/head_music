# A module for musical analysis
module HeadMusic::Analysis; end

# Spellings placed on the line of fifths, after Temperley, The Cognition of
# Basic Musical Structures (2001), and Meredith, "The ps13 pitch spelling
# algorithm," Journal of New Music Research 35 (2006). C is 0, each fifth up
# adds one, and each sharp adds seven: F♭ -8, F -1, C 0, G 1, F♯ 6, B♯ 12.
module HeadMusic::Analysis::LineOfFifths
  LETTER_INDICES = {"F" => -1, "C" => 0, "G" => 1, "D" => 2, "A" => 3, "E" => 4, "B" => 5}.freeze
  LETTERS = LETTER_INDICES.keys.freeze
  RANGE = (-15..19)

  # Built once, because Alteration.by searches every alteration on each call.
  SPELLINGS = RANGE.to_h do |index|
    letter = LETTERS[(index + 1) % 7]
    semitones = (index + 1).div(7)
    alteration = HeadMusic::Rudiment::Alteration.by(:semitones, semitones) unless semitones.zero?
    [index, HeadMusic::Rudiment::Spelling.fetch_or_create(HeadMusic::Rudiment::LetterName.get(letter), alteration)]
  end.freeze

  module_function

  def index_of(spelling)
    spelling = HeadMusic::Rudiment::Spelling.get(spelling)
    LETTER_INDICES.fetch(spelling.letter_name.to_s) + 7 * (spelling.alteration&.semitones || 0)
  end

  def spelling_at(index)
    SPELLINGS[index]
  end

  def pitch_class_of(index)
    (7 * index) % 12
  end

  # The pitch of a key number spelled at an index, or nil where the catalog has
  # none: past a double accidental, or outside registers -1 through 9.
  def pitch_at(number, index)
    spelling = SPELLINGS[index]
    return unless spelling

    offset = number - spelling.semitones_above_c
    return unless (offset % 12).zero?

    pitch = HeadMusic::Rudiment::Pitch.fetch_or_create(spelling, offset / 12 - 1)
    pitch if pitch&.midi_note_number == number && pitch.spelling == spelling
  end

  def pitch_for(number, index)
    pitch_at(number, index) || HeadMusic::Rudiment::Pitch.from_number(number)
  end
end
