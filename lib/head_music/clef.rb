# frozen_string_literal: true

require 'yaml'

# A clef assigns pitches to the lines and spaces of a staff.
class HeadMusic::Clef
  include HeadMusic::Named

  CLEF_RECORDS = YAML.load_file(File.expand_path('clefs.yml', __dir__)).freeze

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

  private_class_method :new

  private

  def initialize(name)
    clef_record = clef_record_for_name(name)
    initialize_data_from_record(clef_record)
  end

  def clef_record_for_name(name)
    key = HeadMusic::Utilities::HashKey.for(name)
    CLEF_RECORDS.detect do |clef_record|
      name_strings = clef_record[:localized_names].map { |localized_name| localized_name[:name] }
      name_keys = name_strings.map { |name_string| HeadMusic::Utilities::HashKey.for(name_string) }
      name_keys.include?(key)
    end
  end

  def initialize_data_from_record(record)
    @pitch = HeadMusic::Pitch.get(record[:pitch])
    @line = record[:line]
    @modern = record[:modern]
    initialize_localized_names(record[:localized_names])
    initialize_musical_symbols(record[:symbols])
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
