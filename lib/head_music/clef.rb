# frozen_string_literal: true

# A clef assigns pitches to the lines and spaces of a staff.
class HeadMusic::Clef
  include HeadMusic::NamedRudiment

  CLEFS = [
    { pitch: 'G4', line: 2, names: ['treble', 'G-clef'], modern: true },
    { pitch: 'G4', line: 1, names: ['French', 'French violin'] },
    { pitch: 'G3', line: 2, names: ['choral tenor', 'tenor'], modern: true },

    { pitch: 'F3', line: 3, names: ['baritone'] },
    { pitch: 'F3', line: 4, names: ['bass', 'F-clef'], modern: true },
    { pitch: 'F3', line: 5, names: ['sub-bass'] },

    { pitch: 'C4', line: 1, names: ['soprano'] },
    { pitch: 'C4', line: 2, names: ['mezzo-soprano'] },
    { pitch: 'C4', line: 3, names: ['alto', 'viola', 'counter-tenor', 'countertenor', 'C-clef'], modern: true },
    { pitch: 'C4', line: 4, names: ['tenor'], modern: true },
    { pitch: 'C4', line: 5, names: ['baritone'] },

    { pitch: nil, line: 3, names: %w[neutral percussion] },
  ].freeze

  def self.get(name)
    get_by_name(name)
  end

  attr_reader :pitch, :line

  def initialize(name)
    @name = name.to_s
    clef_data = CLEFS.detect { |clef| clef[:names].map(&:downcase).include?(name.downcase) }
    @pitch = HeadMusic::Pitch.get(clef_data[:pitch])
    @line = clef_data[:line]
  end

  def clef_type
    "#{pitch.letter_name}-clef"
  end

  def line_pitch(line_number)
    @line_pitches ||= {}
    @line_pitches[line_number] ||= begin
      steps = (line_number - line) * 2
      pitch.natural_steps(steps)
    end
  end

  def space_pitch(space_number)
    @space_pitches ||= {}
    @space_pitches[space_number] ||= begin
      steps = (space_number - line) * 2 + 1
      pitch.natural_steps(steps)
    end
  end

  def ==(other)
    to_s == other.to_s
  end
end
