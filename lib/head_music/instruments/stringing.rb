module HeadMusic::Instruments; end

# The string configuration for a stringed instrument.
#
# A Stringing defines the courses (strings) of an instrument and their
# standard tuning pitches. Each course can have one or more strings.
#
# Examples:
#   guitar = HeadMusic::Instruments::Instrument.get("guitar")
#   stringing = HeadMusic::Instruments::Stringing.for_instrument(guitar)
#   stringing.courses.map(&:standard_pitch)  # => [E2, A2, D3, G3, B3, E4]
class HeadMusic::Instruments::Stringing
  STRINGINGS = YAML.load_file(File.expand_path("stringings.yml", __dir__)).freeze

  attr_reader :instrument_key, :courses

  class << self
    # Find the stringing for an instrument
    # @param instrument [HeadMusic::Instruments::Instrument, String, Symbol] The instrument
    # @return [Stringing, nil]
    def for_instrument(instrument)
      instrument_key = normalize_instrument_key(instrument)
      return nil unless instrument_key

      data = find_stringing_data(instrument_key, instrument)
      return nil unless data

      new(instrument_key: instrument_key, courses_data: data["courses"])
    end

    private

    def normalize_instrument_key(instrument)
      case instrument
      when HeadMusic::Instruments::Instrument
        instrument.name_key.to_s
      else
        instrument.to_s
      end
    end

    def find_stringing_data(instrument_key, instrument)
      # Direct match
      return STRINGINGS[instrument_key] if STRINGINGS.key?(instrument_key)

      # Try parent instrument if this is an Instrument object
      if instrument.is_a?(HeadMusic::Instruments::Instrument) && instrument.parent
        parent_key = instrument.parent.name_key.to_s
        return STRINGINGS[parent_key] if STRINGINGS.key?(parent_key)
      end

      nil
    end
  end

  def initialize(instrument_key:, courses_data:)
    @instrument_key = instrument_key.to_sym
    @courses = build_courses(courses_data)
  end

  # The instrument this stringing belongs to
  # @return [HeadMusic::Instruments::Instrument]
  def instrument
    HeadMusic::Instruments::Instrument.get(instrument_key)
  end

  # Number of courses
  # @return [Integer]
  def course_count
    courses.length
  end

  # Total number of physical strings across all courses
  # @return [Integer]
  def string_count
    courses.sum(&:string_count)
  end

  # Standard pitches for each course (primary string only)
  # @return [Array<HeadMusic::Rudiment::Pitch>]
  def standard_pitches
    courses.map(&:standard_pitch)
  end

  # Apply an alternate tuning to get adjusted pitches
  # @param tuning [AlternateTuning] The alternate tuning to apply
  # @return [Array<HeadMusic::Rudiment::Pitch>]
  def pitches_with_tuning(tuning)
    courses.each_with_index.map do |course, index|
      semitone_adjustment = tuning.semitones[index] || 0
      HeadMusic::Rudiment::Pitch.from_number(course.standard_pitch.to_i + semitone_adjustment)
    end
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    instrument_key == other.instrument_key && courses == other.courses
  end

  def to_s
    "#{course_count}-course stringing for #{instrument_key}"
  end

  private

  def build_courses(courses_data)
    courses_data.map do |course_data|
      HeadMusic::Instruments::StringingCourse.new(
        standard_pitch: course_data["pitch"],
        course_semitones: course_data["course_semitones"] || []
      )
    end
  end
end
