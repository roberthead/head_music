# frozen_string_literal: true

# A scale contains ordered pitches starting at a tonal center.
class HeadMusic::Scale
  SCALE_REGEX = /^[A-G][#b]?\s+\w+$/

  def self.get(root_pitch, scale_type = nil)
    root_pitch, scale_type = root_pitch.split(/\s+/) if root_pitch.is_a?(String) && scale_type =~ SCALE_REGEX
    root_pitch = HeadMusic::Pitch.get(root_pitch)
    scale_type = HeadMusic::ScaleType.get(scale_type || :major)
    @scales ||= {}
    identifier = [root_pitch, scale_type].join(' ').gsub(/#|♯/, 'sharp').gsub(/(\w)[b♭]/, '\\1flat')
    hash_key = HeadMusic::Utilities::HashKey.for(identifier)
    @scales[hash_key] ||= new(root_pitch, scale_type)
  end

  delegate :letter_name_cycle, to: :root_pitch

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

  def spellings(direction: :ascending, octaves: 1)
    pitches(direction: direction, octaves: octaves).map(&:spelling).map(&:to_s)
  end

  def pitch_names(direction: :ascending, octaves: 1)
    pitches(direction: direction, octaves: octaves).map(&:name)
  end

  def root_pitch_number
    @root_pitch_number ||= root_pitch.number
  end

  def degree(degree_number)
    pitches[degree_number - 1]
  end

  private

  def determine_scale_pitches(direction, octaves)
    semitones_from_root = 0
    pitches = [root_pitch]
    %i[ascending descending].each do |single_direction|
      next unless [single_direction, :both].include?(direction)
      (1..octaves).each do
        pitches += octave_scale_pitches(single_direction, semitones_from_root)
        semitones_from_root += 12 * direction_sign(single_direction)
      end
    end
    pitches
  end

  def octave_scale_pitches(direction, semitones_from_root)
    direction_intervals(direction).map.with_index(1) do |semitones, i|
      semitones_from_root += semitones * direction_sign(direction)
      pitch_for_step(i, semitones_from_root, direction)
    end
  end

  def direction_sign(direction)
    direction == :descending ? -1 : 1
  end

  def direction_intervals(direction)
    scale_type.send("#{direction}_intervals")
  end

  def parent_scale_pitches
    HeadMusic::Scale.get(root_pitch, scale_type.parent_name).pitches if scale_type.parent
  end

  def parent_scale_pitch_for(semitones_from_root)
    parent_scale_pitches.detect do |parent_scale_pitch|
      parent_scale_pitch.pitch_class == (root_pitch + semitones_from_root).to_i % 12
    end
  end

  def pitch_for_step(step, semitones_from_root, direction)
    pitch_number = root_pitch_number + semitones_from_root
    letter_name = letter_for_step(step, semitones_from_root, direction)
    HeadMusic::Pitch.from_number_and_letter(pitch_number, letter_name)
  end

  def letter_for_step(step, semitones_from_root, direction)
    diatonic_letter_for_step(direction, step) ||
      child_scale_letter_for_step(semitones_from_root) ||
      flat_letter_for_step(semitones_from_root) ||
      sharp_letter_for_step(semitones_from_root)
  end

  def diatonic_letter_for_step(direction, step)
    return unless scale_type.diatonic?
    direction == :ascending ? letter_name_cycle[step % 7] : letter_name_cycle[-step % 7]
  end

  def child_scale_letter_for_step(semitones_from_root)
    return unless scale_type.parent
    parent_scale_pitch_for(semitones_from_root).letter_name
  end

  def flat_letter_for_step(semitones_from_root)
    return unless root_pitch.flat?
    HeadMusic::PitchClass::FLAT_SPELLINGS[pitch_class_number(semitones_from_root)]
  end

  def sharp_letter_for_step(semitones_from_root)
    HeadMusic::PitchClass::SHARP_SPELLINGS[pitch_class_number(semitones_from_root)]
  end

  def pitch_class_number(semitones_from_root)
    (root_pitch.pitch_class.to_i + semitones_from_root) % 12
  end
end
