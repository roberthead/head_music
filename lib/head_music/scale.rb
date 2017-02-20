class HeadMusic::Scale
  def self.get(root_pitch, scale_type_name = nil)
    root_pitch = HeadMusic::Pitch.get(root_pitch)
    scale_type_name ||= :major
    scale_type ||= HeadMusic::ScaleType.get(scale_type_name)
    @scales ||= {}
    @scales[root_pitch.to_s] ||= {}
    @scales[root_pitch.to_s][scale_type.name] ||= new(root_pitch, scale_type)
  end

  attr_reader :root_pitch, :scale_type

  def initialize(root_pitch, scale_type)
    @root_pitch = HeadMusic::Pitch.get(root_pitch)
    @scale_type = HeadMusic::ScaleType.get(scale_type)
  end

  def pitches
    @pitches ||= begin
      letter_cycle = root_pitch.letter_cycle
      semitones_from_root = 0
      [root_pitch].tap do |pitches|
        scale_type.intervals.each_with_index do |semitones, i|
          semitones_from_root += semitones
          pitches << pitch_for_step(i+1, semitones_from_root)
        end
      end
    end
  end

  def pitch_names
    pitches.map(&:spelling).map(&:to_s)
  end

  def in(spelling)
    spelling = HeadMusic::Spelling.get(spelling.to_s)
    spellings = []
    letter_index = HeadMusic::Letter::all.index(spelling.letter)
    starting_pitch_class = spelling.pitch_class
    pattern.each do |interval_from_tonic|
      letter = HeadMusic::Letter.all[letter_index]
      if interval_from_tonic
        accidental_interval = letter.pitch_class.smallest_interval_to(HeadMusic::PitchClass.get(starting_pitch_class + interval_from_tonic))
        accidental = HeadMusic::Accidental.for_interval(accidental_interval)
        spellings << HeadMusic::Spelling.get([letter, accidental].join)
      end
      letter_index = (letter_index + 1) % 7
    end
    spellings
  end

  def letter_cycle
    @letter_cycle ||= root_pitch.letter_cycle
  end

  def root_pitch_class
    @root_pitch_class ||= root_pitch.pitch_class
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

  def letter_for_step(step, semitones_from_root)
    pitch_class_number = (root_pitch.pitch_class.to_i + semitones_from_root) % 12
    if scale_type.intervals.length == 7
      letter_cycle[step % 7]
    elsif scale_type.intervals.length < 7 && parent_scale_pitches
      parent_scale_pitch_for(semitones_from_root).letter
    elsif root_pitch.flat?
      HeadMusic::PitchClass::FLAT_SPELLINGS[pitch_class_number]
    else
      HeadMusic::PitchClass::SHARP_SPELLINGS[pitch_class_number]
    end
  end

  def pitch_for_step(step, semitones_from_root)
    pitch_number = root_pitch_class.to_i + semitones_from_root
    letter = letter_for_step(step, semitones_from_root)
    HeadMusic::Pitch.from_number_and_letter(pitch_number, letter)
  end
end
