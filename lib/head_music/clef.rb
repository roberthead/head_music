# frozen_string_literal: true

require "yaml"

# A clef assigns pitches to the lines and spaces of a staff.
class HeadMusic::Clef
  include HeadMusic::Named

  RECORDS = YAML.load_file(File.expand_path("data/clefs.yml", __dir__)).freeze

  def self.get(name)
    get_by_name(name)
  end

  attr_reader :pitch, :line, :musical_symbols

  delegate :ascii, :html_entity, :unicode, to: :musical_symbol

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

  def name(locale_code: Locale::DEFAULT_CODE)
    I18n.translate(name_key, scope: "head_music.clefs", locale: locale_code)
  end

  private_class_method :new

  private

  def initialize(name)
    record = record_for_name(name)
    initialize_data_from_record(record)
  end

  def record_for_name(name)
    name = name.to_s.strip
    key = HeadMusic::Utilities::HashKey.for(name)
    RECORDS.detect do |record|
      name_keys = name_keys_from_record(record)
      name_keys.include?(key) || name_key_translations(name_keys).include?(name)
    end
  end

  def name_keys_from_record(record)
    ([record[:name_key]] + [record[:alias_name_keys]]).flatten.compact.uniq.map(&:to_sym)
  end

  def name_key_translations(name_keys)
    name_keys.map do |name_key|
      I18n.config.available_locales.map do |locale_code|
        I18n.translate(name_key, scope: "head_music.clefs", locale: locale_code)
      end.flatten.uniq.compact
    end.flatten.uniq.compact
  end

  def initialize_data_from_record(record)
    initialize_keys_from_record(record)
    @pitch = HeadMusic::Pitch.get(record[:pitch])
    @line = record[:line]
    @modern = record[:modern]
    initialize_musical_symbols(record[:symbols])
  end

  def initialize_keys_from_record(record)
    @name_key = record[:name_key]
    @alias_name_keys = [record[:alias_name_keys]].flatten.compact
  end

  def initialize_musical_symbols(list)
    @musical_symbols = (list || []).map do |symbol_data|
      HeadMusic::MusicalSymbol.new(**symbol_data.slice(:ascii, :html_entity, :unicode))
    end
  end
end
