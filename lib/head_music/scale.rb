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
      pitches = [root_pitch]
      letters_cycle = HeadMusic::Letter::NAMES
      letters_cycle = letters_cycle.rotate while letters_cycle.first != root_pitch.letter.to_s
      semitones_from_root = 0
      if scale_type.parent
        parent_scale_pitches = HeadMusic::Scale.get(root_pitch, scale_type.parent_name).pitches
      end
      scale_type.intervals.each_with_index do |semitones, i|
        semitones_from_root += semitones
        pitch_number = root_pitch.pitch_class.to_i + semitones_from_root
        if scale_type.intervals.length == 7
          current_letter = letters_cycle[(i + 1) % 7]
        elsif scale_type.intervals.length < 7 && scale_type.parent
          current_letter = parent_scale_pitches.detect { |parent_scale_pitches|
            parent_scale_pitches.pitch_class == (root_pitch + semitones_from_root).to_i % 12
          }.letter
        elsif root_pitch.flat?
          current_letter = HeadMusic::PitchClass::FLAT_SPELLINGS[pitch_number % 12]
        else
          current_letter = HeadMusic::PitchClass::SHARP_SPELLINGS[pitch_number % 12]
        end
        pitch = HeadMusic::Pitch.from_number_and_letter(pitch_number, current_letter)
        pitches << pitch
      end
      pitches
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
end
