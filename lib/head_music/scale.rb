class HeadMusic::Scale
  SCALE_REGEX = /^[A-G][#b]?\s+\w+$/

  def self.get(root_pitch, scale_type = nil)
    if root_pitch.is_a?(String) && scale_type =~ SCALE_REGEX
      root_pitch, scale_type = root_pitch.split(/\s+/)
    end
    root_pitch = HeadMusic::Pitch.get(root_pitch)
    scale_type = HeadMusic::ScaleType.get(scale_type || :major)
    @scales ||= {}
    name = [root_pitch, scale_type].join(' ')
    hash_key = HeadMusic::Utilities::HashKey.for(name)
    @scales[hash_key] ||= new(root_pitch, scale_type)
  end

  attr_reader :root_pitch, :scale_type

  def initialize(root_pitch, scale_type)
    @root_pitch = HeadMusic::Pitch.get(root_pitch)
    @scale_type = HeadMusic::ScaleType.get(scale_type)
  end

  def pitches(direction: :ascending, octaves: 1)
    @pitches ||= {}
    @pitches[direction] ||= {}
    @pitches[direction][octaves] ||= determine_scale_pitches(direction, octaves)
  end

  def determine_scale_pitches(direction, octaves)
    semitones_from_root = 0
    [root_pitch].tap do |pitches|
      [:ascending, :descending].each do |single_direction|
        if [single_direction, :both].include?(direction)
          (1..octaves).each do
            direction_intervals(single_direction).each_with_index do |semitones, i|
              semitones_from_root += semitones * direction_sign(single_direction)
              pitches << pitch_for_step(i+1, semitones_from_root, single_direction)
            end
          end
        end
      end
    end
  end

  def direction_sign(direction)
    direction == :descending ? -1 : 1
  end

  def direction_intervals(direction)
    scale_type.send("#{direction}_intervals")
  end

  def spellings(direction: :ascending, octaves: 1)
    pitches(direction: direction, octaves: octaves).map(&:spelling).map(&:to_s)
  end

  def pitch_names(direction: :ascending, octaves: 1)
    pitches(direction: direction, octaves: octaves).map(&:name)
  end

  def letter_name_cycle
    @letter_name_cycle ||= root_pitch.letter_name_cycle
  end

  def root_pitch_number
    @root_pitch_number ||= root_pitch.number
  end

  def degree(degree_number)
    pitches[degree_number - 1]
  end

  private

  def parent_scale_pitches
    HeadMusic::Scale.get(root_pitch, scale_type.parent_name).pitches if scale_type.parent
  end

  def parent_scale_pitch_for(semitones_from_root)
    parent_scale_pitches.detect { |parent_scale_pitch|
      parent_scale_pitch.pitch_class == (root_pitch + semitones_from_root).to_i % 12
    }
  end

  def letter_for_step(step, semitones_from_root, direction)
    pitch_class_number = (root_pitch.pitch_class.to_i + semitones_from_root) % 12
    if scale_type.intervals.length == 7
      direction == :ascending ? letter_name_cycle[step % 7] : letter_name_cycle[-step % 7]
    elsif scale_type.intervals.length < 7 && parent_scale_pitches
      parent_scale_pitch_for(semitones_from_root).letter_name
    elsif root_pitch.flat?
      HeadMusic::PitchClass::FLAT_SPELLINGS[pitch_class_number]
    else
      HeadMusic::PitchClass::SHARP_SPELLINGS[pitch_class_number]
    end
  end

  def pitch_for_step(step, semitones_from_root, direction)
    pitch_number = root_pitch_number + semitones_from_root
    letter_name = letter_for_step(step, semitones_from_root, direction)
    HeadMusic::Pitch.from_number_and_letter(pitch_number, letter_name)
  end
end
