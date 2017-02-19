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
      letters_cycle = Letter::NAMES
      letters_cycle = letters_cycle.rotate while letters_cycle.first != root_pitch.letter.to_s
      scale_type.intervals.each do |semitones|
        letters_cycle = letters_cycle.rotate((semitones + 1) / 2)
        number = pitches.last.to_i + semitones
        pitch = HeadMusic::Pitch.from_number_and_letter(number, letters_cycle.first)
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
