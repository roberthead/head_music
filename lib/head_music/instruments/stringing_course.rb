module HeadMusic::Instruments; end

# A single course (string or set of strings) on a stringed instrument.
#
# A "course" is a set of strings that are played together. On most guitars,
# each course has a single string. On a 12-string guitar or mandolin,
# courses have multiple strings tuned in unison or octaves.
#
# Examples:
#   - 6-string guitar: 6 courses, each with 1 string
#   - 12-string guitar: 6 courses, each with 2 strings (octave or unison)
#   - Mandolin: 4 courses, each with 2 strings in unison
class HeadMusic::Instruments::StringingCourse
  attr_reader :standard_pitch, :course_semitones

  # @param standard_pitch [HeadMusic::Rudiment::Pitch, String] The pitch of the primary string
  # @param course_semitones [Array<Integer>] Semitone offsets for additional strings in the course
  def initialize(standard_pitch:, course_semitones: [])
    @standard_pitch = HeadMusic::Rudiment::Pitch.get(standard_pitch)
    @course_semitones = Array(course_semitones)
  end

  # Returns all pitches in this course (primary + additional strings)
  # @return [Array<HeadMusic::Rudiment::Pitch>]
  def pitches
    [standard_pitch] + additional_pitches
  end

  # Returns the number of physical strings in this course
  # @return [Integer]
  def string_count
    1 + course_semitones.length
  end

  # Whether this course has multiple strings
  # @return [Boolean]
  def doubled?
    course_semitones.any?
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    standard_pitch == other.standard_pitch && course_semitones == other.course_semitones
  end

  def to_s
    standard_pitch.to_s
  end

  private

  def additional_pitches
    course_semitones.map do |semitones|
      HeadMusic::Rudiment::Pitch.from_number(standard_pitch.to_i + semitones)
    end
  end
end
