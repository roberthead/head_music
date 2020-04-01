# frozen_string_literal: true

# A clef assigns pitches to the lines and spaces of a staff.
class HeadMusic::Clef
  include HeadMusic::Named

  CLEF_RECORDS = [
    {
      pitch: 'G4', line: 2, modern: true,
      localized_names: [
        { name: 'treble clef' },
        { name: 'G-clef' },
        { name: 'clave de sol', locale_code: 'es' },
        { name: 'clef de sol', locale_code: 'fr' },
        { name: 'clé de sol', locale_code: 'fr' },
        { name: 'clef de sol 2e', locale_code: 'fr' },
        { name: 'clé de sol 2e', locale_code: 'fr' },
        { name: 'Violinschlüssel', locale_code: 'de' },
        { name: 'chiave di violino', locale_code: 'it' },
      ],
      symbols: [{ unicode: '𝄞', html_entity: '&#119070;' }],
    },
    {
      pitch: 'G4', line: 1,
      localized_names: [
        { name: 'French clef' },
        { name: 'French violin clef' },
        { name: 'clef de sol 1re', locale_code: 'fr' },
        { name: 'clé de sol 1re', locale_code: 'fr' },
      ],
      symbols: [{ unicode: '𝄞', html_entity: '&#119070;' }],
    },
    {
      pitch: 'G3', line: 2, modern: true,
      localized_names: [
        { name: 'choral tenor clef' },
        { name: 'tenor clef' },
        { name: 'tenor G-clef' },
      ],
      symbols: [{ unicode: '𝄠', html_entity: '&#119072;' }],
    },
    {
      pitch: 'G3', line: 2,
      localized_names: [{ name: 'double treble clef' }],
      symbols: [{ unicode: '𝄞𝄞', html_entity: '&#119070;&#119070;' }],
    },
    {
      pitch: 'F3', line: 3,
      localized_names: [
        { name: 'baritone clef' },
        { name: 'baritone F-clef' },
        { name: 'clave de fa en tercera', locale_code: 'es' },
        { name: 'clave de barítono', locale_code: 'es' },
        { name: 'clef de fa troisième ligne', locale_code: 'fr' },
        { name: 'clé de fa troisième ligne', locale_code: 'fr' },
        { name: 'clef de fa 3e', locale_code: 'fr' },
        { name: 'clé de fa 3e', locale_code: 'fr' },
        { name: 'Baritonschlüssel', locale_code: 'de' },
        { name: 'chiave di baritono', locale_code: 'it' },
      ],
      symbols: [{ unicode: '𝄢', html_entity: '&#119074;' }],
    },
    {
      pitch: 'F3', line: 4, modern: true,
      localized_names: [
        { name: 'bass clef' },
        { name: 'F-clef' },
        { name: 'clave de fa', locale_code: 'es' },
        { name: 'clave de fa en cuarta', locale_code: 'es' },
        { name: 'clef de fa', locale_code: 'fr' },
        { name: 'clé de fa', locale_code: 'fr' },
        { name: 'clef de fa quatrième ligne', locale_code: 'fr' },
        { name: 'clé de fa quatrième ligne', locale_code: 'fr' },
        { name: 'clef de fa 4e', locale_code: 'fr' },
        { name: 'clé de fa 4e', locale_code: 'fr' },
        { name: 'clef de basse', locale_code: 'fr' },
        { name: 'clé de basse', locale_code: 'fr' },
        { name: 'Bassschlüssel', locale_code: 'de' },
        { name: 'F-Schlüssel', locale_code: 'de' },
        { name: 'Bass-Schlüssel', locale_code: 'de' },
        { name: 'chiave di basso', locale_code: 'it' },
        { name: 'chiave di Fa2', locale_code: 'it' },
      ],
      symbols: [{ unicode: '𝄢', html_entity: '&#119074;' }],
    },
    {
      pitch: 'F3', line: 5,
      localized_names: [
        { name: 'sub-bass clef' },
        { name: 'subbass clef' },
        { name: 'contrabass clef' },
        { name: 'clave de fa en quinta', locale_code: 'es' },
        { name: 'clef de fa 5e', locale_code: 'fr' },
        { name: 'clé de fa 5e', locale_code: 'fr' },
        { name: 'Subbassschlüssel', locale_code: 'de' },
        { name: 'chiave di basso profondo', locale_code: 'it' },
      ],
      symbols: [{ unicode: '𝄢', html_entity: '&#119074;' }],
    },
    {
      pitch: 'C4', line: 1,
      localized_names: [
        { name: 'soprano clef' },
        { name: 'clave de do en primera', locale_code: 'es' },
        { name: 'clave de soprano', locale_code: 'es' },
        { name: "clef d'ut 1re", locale_code: 'fr' },
        { name: "clé d'ut 1re", locale_code: 'fr' },
        { name: 'Sopranschlüssel', locale_code: 'de' },
        { name: 'Diskantschlüssel', locale_code: 'de' },
        { name: 'chiave di soprano', locale_code: 'it' },
      ],
      symbols: [{ unicode: '𝄡', html_entity: '&#119073;' }],
    },
    {
      pitch: 'C4', line: 2,
      localized_names: [
        { name: 'mezzo-soprano clef' },
        { name: 'clave de do en segunda', locale_code: 'es' },
        { name: 'clave de mezzosoprano', locale_code: 'es' },
        { name: 'clef de mezzo-soprano', locale_code: 'fr' },
        { name: 'clé de mezzo-soprano', locale_code: 'fr' },
        { name: "clef d'ut 2e", locale_code: 'fr' },
        { name: "clé d'ut 2e", locale_code: 'fr' },
        { name: 'Mezzosopranschlüssel', locale_code: 'de' },
        { name: 'chiave di mezzosoprano', locale_code: 'it' },
      ],
      symbols: [{ unicode: '𝄡', html_entity: '&#119073;' }],
    },
    {
      pitch: 'C4', line: 3, modern: true,
      localized_names: [
        { name: 'alto clef' },
        { name: 'C-clef' },
        { name: 'viola clef' },
        { name: 'counter-tenor clef' },
        { name: 'countertenor clef' },
        { name: 'clave de do', locale_code: 'es' },
        { name: 'clave de do en tercera', locale_code: 'es' },
        { name: 'clave de contralto', locale_code: 'es' },
        { name: "clef d'ut", locale_code: 'fr' },
        { name: "clé d'ut", locale_code: 'fr' },
        { name: "clef d'ut troisième ligne", locale_code: 'fr' },
        { name: "clé d'ut troisième ligne", locale_code: 'fr' },
        { name: "clef d'ut 3e", locale_code: 'fr' },
        { name: "clé d'ut 3e", locale_code: 'fr' },
        { name: 'clef alto', locale_code: 'fr' },
        { name: 'Altschlüssel', locale_code: 'de' },
        { name: 'Bratschenschlüssel', locale_code: 'de' },
        { name: 'chiave di contralto', locale_code: 'it' },
        { name: 'chiave di Do', locale_code: 'it' },
        { name: 'chiave di Do3', locale_code: 'it' },
      ],
      symbols: [{ unicode: '𝄡', html_entity: '&#119073;' }],
    },
    {
      pitch: 'C4', line: 4, modern: true,
      localized_names: [
        { name: 'tenor clef' },
        { name: 'tenor C-clef' },
        { name: 'clave de do en cuarta', locale_code: 'es' },
        { name: 'clave de tenor', locale_code: 'es' },
        { name: 'clef de ténor', locale_code: 'fr' },
        { name: 'clé de ténor', locale_code: 'fr' },
        { name: "clef d'ut 4e", locale_code: 'fr' },
        { name: "clé d'ut 4e", locale_code: 'fr' },
        { name: 'Tenorschlüssel', locale_code: 'de' },
        { name: 'chiave di tenore', locale_code: 'it' },
      ],
      symbols: [{ unicode: '𝄡', html_entity: '&#119073;' }],
    },
    {
      pitch: 'C4', line: 5,
      localized_names: [
        { name: 'baritone C-clef' },
        { name: 'baritone clef' },
        { name: 'clave de do en quinta', locale_code: 'es' },
        { name: 'clave de barítono', locale_code: 'es' },
        { name: "clef d'ut cinquième ligne", locale_code: 'fr' },
        { name: "clé d'ut cinquième ligne", locale_code: 'fr' },
        { name: "clef d'ut 5e", locale_code: 'fr' },
        { name: "clé d'ut 5e", locale_code: 'fr' },
        { name: 'Baritonschlüssel', locale_code: 'de' },
        { name: 'chiave di baritono', locale_code: 'it' },
      ],
      symbols: [{ unicode: '𝄡', html_entity: '&#119073;' }],
    },
    {
      pitch: nil, line: 3, modern: true,
      localized_names: [
        { name: 'neutral clef' },
        { name: 'indefinite pitch clef' },
        { name: 'percussion clef' },
        { name: 'rhythm clef' },
        { name: 'drum clef' },
        { name: 'clave neutral', locale_code: 'es' },
        { name: 'clave para percusión', locale_code: 'es' },
        { name: 'clé neutre', locale_code: 'fr' },
        { name: 'Schlagzeugschlüssel', locale_code: 'de' },
        { name: 'chiave neutra', locale_code: 'it' },
      ],
      symbols: [
        { unicode: '𝄥', html_entity: '&#119077;' },
        { unicode: '𝄦', html_entity: '&#119078;' },
      ],
    },
  ].freeze

  def self.get(name)
    get_by_name(name)
  end

  attr_reader :pitch, :line, :musical_symbols

  delegate :ascii, :html_entity, :unicode, to: :musical_symbol

  def initialize(name)
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
    HeadMusic::Utilities::HashKey.for(self) == HeadMusic::Utilities::HashKey.for(other)
  end

  private

  def clef_record_for_name(name)
    key = HeadMusic::Utilities::HashKey.for(name)
    CLEF_RECORDS.detect do |clef_record|
      name_strings = clef_record[:localized_names].map { |localized_name| localized_name[:name] }
      name_keys = name_strings.map { |name_string| HeadMusic::Utilities::HashKey.for(name_string) }
      name_keys.include?(key)
    end
  end

  def initialize_data_from_record(clef_record)
    @pitch = HeadMusic::Pitch.get(clef_record[:pitch])
    @line = clef_record[:line]
    @modern = clef_record[:modern]
    initialize_localized_names(clef_record[:localized_names])
    initialize_musical_symbols(clef_record[:symbols])
  end

  def initialize_localized_names(list)
    @localized_names = (list || []).map do |name_attributes|
      HeadMusic::Named::LocalizedName.new(name_attributes.slice(:name, :locale_code, :abbreviation))
    end
  end

  def initialize_musical_symbols(list)
    @musical_symbols = (list || []).map do |symbol_data|
      HeadMusic::MusicalSymbol.new(symbol_data.slice(:ascii, :html_entity, :unicode))
    end
  end
end
