class HeadMusic::Rudiment::RhythmicUnit::Parser
  attr_reader :rhythmic_unit, :identifier

  RHYTHMIC_UNITS_DATA = HeadMusic::Rudiment::RhythmicUnit::RHYTHMIC_UNITS_DATA

  TEMPO_SHORTHAND_PATTERN = RHYTHMIC_UNITS_DATA.map { |unit| unit["tempo_shorthand"] }.compact.uniq.sort_by { |s| -s.length }.join("|")

  def self.parse(identifier)
    return nil if identifier.nil? || identifier.to_s.strip.empty?
    new(identifier).parsed_name
  end

  def initialize(identifier)
    @identifier = identifier.to_s.strip
    parse
  end

  def parse
    @unit_data = from_american_name || from_british_name || from_tempo_shorthand || from_duration
    @rhythmic_unit = @unit_data ? HeadMusic::Rudiment::RhythmicUnit.get_by_name(@unit_data["american_name"]) : nil
  end

  def parsed_name
    # Return the name format that was used in input
    return nil unless @unit_data

    # Check which type matched
    if from_british_name == @unit_data && @unit_data["british_name"]
      @unit_data["british_name"]
    else
      @unit_data["american_name"]
    end
  end

  def american_name
    # Always return the American name if a unit was found
    @unit_data&.fetch("american_name", nil)
  end

  def normalized_identifier
    @normalized_identifier ||= identifier.downcase.strip.gsub(/[^a-z0-9]/, "_").squeeze("_").gsub(/^_|_$/, "")
  end

  def from_american_name
    RHYTHMIC_UNITS_DATA.find do |unit|
      normalize_name(unit["american_name"]) == normalized_identifier
    end
  end

  def from_british_name
    RHYTHMIC_UNITS_DATA.find do |unit|
      normalize_name(unit["british_name"]) == normalized_identifier
    end
  end

  def from_tempo_shorthand
    # Handle shorthand with dots (e.g., "q." should match "q")
    clean_identifier = identifier.downcase.strip.gsub(/\.*$/, "")
    RHYTHMIC_UNITS_DATA.find do |unit|
      unit["tempo_shorthand"] && unit["tempo_shorthand"].downcase == clean_identifier
    end
  end

  def from_duration
    RHYTHMIC_UNITS_DATA.find do |unit|
      # Match decimal duration (e.g., "0.25")
      return unit if unit["duration"].to_s == identifier.strip

      # Match fraction notation (e.g., "1/4" = 0.25)
      if identifier.match?(%r{^\d+/\d+$})
        numerator, denominator = identifier.split("/").map(&:to_f)
        calculated_duration = numerator / denominator
        return unit if (calculated_duration - unit["duration"]).abs < 0.0001
      end

      false
    end
  end

  private

  def normalize_name(name)
    return nil if name.nil?
    name.to_s.downcase.strip.gsub(/[^a-z0-9]/, "_").squeeze("_").gsub(/^_|_$/, "")
  end
end
