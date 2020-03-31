# frozen_string_literal: true

# A clef assigns pitches to the lines and spaces of a staff.
class HeadMusic::Clef
  include HeadMusic::Named

  CLEF_RECORDS = [
    {
      pitch: 'G4', line: 2,
      names: %w[treble G-clef],
      modern: true,
      symbols: [{ unicode: '𝄞', html_entity: '&#119070;' }],
    },
    {
      pitch: 'G4', line: 1,
      names: ['French', 'French violin'],
      symbols: [{ unicode: '𝄞', html_entity: '&#119070;' }],
    },
    {
      pitch: 'G3', line: 2,
      names: ['choral tenor', 'tenor', 'tenor G-clef'],
      modern: true,
      symbols: [{ unicode: '𝄠', html_entity: '&#119072;' }],
    },
    {
      pitch: 'G3', line: 2,
      names: ['double treble'],
      symbols: [{ unicode: '𝄞𝄞', html_entity: '&#119070;&#119070;' }],
    },
    {
      pitch: 'F3', line: 3,
      names: ['baritone'],
      symbols: [{ unicode: '𝄢', html_entity: '&#119074;' }],
    },
    {
      pitch: 'F3', line: 4,
      names: %w[bass F-clef],
      modern: true,
      symbols: [{ unicode: '𝄢', html_entity: '&#119074;' }],
    },
    {
      pitch: 'F3', line: 5,
      names: ['sub-bass'],
      symbols: [{ unicode: '𝄢', html_entity: '&#119074;' }],
    },
    {
      pitch: 'C4', line: 1,
      names: ['soprano'],
      symbols: [{ unicode: '𝄡', html_entity: '&#119073;' }],
    },
    {
      pitch: 'C4', line: 2,
      names: ['mezzo-soprano'],
      symbols: [{ unicode: '𝄡', html_entity: '&#119073;' }],
    },
    {
      pitch: 'C4', line: 3,
      names: %w[alto viola counter-tenor countertenor C-clef],
      modern: true,
      symbols: [{ unicode: '𝄡', html_entity: '&#119073;' }],
    },
    {
      pitch: 'C4', line: 4,
      names: ['tenor', 'tenor C-clef'],
      modern: true,
      symbols: [{ unicode: '𝄡', html_entity: '&#119073;' }],
    },
    {
      pitch: 'C4', line: 5,
      names: ['baritone', 'baritone C-clef'],
      symbols: [{ unicode: '𝄡', html_entity: '&#119073;' }],
    },
    {
      pitch: nil, line: 3,
      names: %w[neutral percussion],
      modern: true,
      symbols: [{ unicode: '𝄥', html_entity: '&#119077;' }, { unicode: '𝄦', html_entity: '&#119078;' }],
    },
  ].freeze

  def self.get(name)
    get_by_name(name)
  end

  attr_reader :pitch, :line, :musical_symbols

  delegate :ascii, :html_entity, :unicode, to: :musical_symbol

  def initialize(name)
    self.name = name.to_s
    clef_record = clef_record_for_name(name)
    initialize_data_from_record(clef_record)
  end

  def musical_symbol
    musical_symbols.first
  end

  def clef_type
    "#{pitch.letter_name}-clef"
  end

  def pitch_for_line(line_number)
    @line_pitches ||= {}
    @line_pitches[line_number] ||= begin
      steps = (line_number - line) * 2
      pitch.natural_steps(steps)
    end
  end

  def pitch_for_space(space_number)
    @space_pitches ||= {}
    @space_pitches[space_number] ||= begin
      steps = (space_number - line) * 2 + 1
      pitch.natural_steps(steps)
    end
  end

  def modern?
    @modern
  end

  def ==(other)
    to_s == other.to_s
  end

  private

  def clef_record_for_name(name)
    CLEF_RECORDS.detect do |clef|
      clef[:names].map do |clef_name|
        HeadMusic::Utilities::HashKey.for(clef_name)
      end.include?(HeadMusic::Utilities::HashKey.for(name))
    end
  end

  def initialize_data_from_record(clef_record)
    @pitch = HeadMusic::Pitch.get(clef_record[:pitch])
    @line = clef_record[:line]
    @modern = clef_record[:modern]
    initialize_musical_symbols(clef_record[:symbols])
  end

  def initialize_musical_symbols(list)
    @musical_symbols = (list || []).map do |symbol_data|
      HeadMusic::MusicalSymbol.new(symbol_data.slice(:ascii, :html_entity, :unicode))
    end
  end
end
