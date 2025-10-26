# A module for musical analysis
module HeadMusic::Analysis; end

# A Dyad is a two-pitch combination that can imply various chords.
# It analyzes the harmonic implications of two pitches sounding together.
class HeadMusic::Analysis::Dyad
  attr_reader :pitch1, :pitch2, :key

  def initialize(pitch1, pitch2, key: nil)
    @pitch1, @pitch2 = [
      HeadMusic::Rudiment::Pitch.get(pitch1),
      HeadMusic::Rudiment::Pitch.get(pitch2)
    ].sort
    @key = key ? HeadMusic::Rudiment::Key.get(key) : nil
  end

  def interval
    @interval ||= HeadMusic::Analysis::DiatonicInterval.new(lower_pitch, upper_pitch)
  end

  def pitches
    [pitch1, pitch2]
  end

  def lower_pitch
    @lower_pitch ||= [pitch1, pitch2].min
  end

  def upper_pitch
    @upper_pitch ||= [pitch1, pitch2].max
  end

  def possible_trichords
    @possible_trichords ||= begin
      trichords = generate_possible_trichords
      trichords = filter_by_key(trichords) if key
      sort_by_diatonic_agreement(trichords)
    end
  end

  def possible_triads
    @possible_triads ||= possible_trichords.select(&:triad?)
  end

  def possible_seventh_chords
    @possible_seventh_chords ||= begin
      seventh_chords = generate_possible_seventh_chords
      seventh_chords = filter_by_key(seventh_chords) if key
      sort_by_diatonic_agreement(seventh_chords)
    end
  end

  def enharmonic_respellings
    @enharmonic_respellings ||= generate_enharmonic_respellings
  end

  def to_s
    "#{pitch1} - #{pitch2}"
  end

  def method_missing(method_name, *args, &block)
    respond_to_missing?(method_name) ? interval.send(method_name, *args, &block) : super
  end

  def respond_to_missing?(method_name, *_args)
    interval.respond_to?(method_name)
  end

  private

  def generate_possible_trichords
    trichords = []
    pitch_classes = [lower_pitch.pitch_class, upper_pitch.pitch_class]

    # Use all possible spelled root pitches in a middle register
    # Only use single sharps/flats to avoid nil pitch creation issues
    root_spellings = %w[C C# Db D D# Eb E F F# Gb G G# Ab A A# Bb B]

    root_spellings.each do |root_spelling|
      root_pitch = HeadMusic::Rudiment::Pitch.get("#{root_spelling}4")
      next unless root_pitch # Skip if pitch creation failed

      # Try all common trichord types from this root
      trichord_intervals = [
        %w[M3 P5],   # major triad
        %w[m3 P5],   # minor triad
        %w[m3 d5],   # diminished triad
        %w[M3 A5],   # augmented triad
        %w[P4 P5],   # sus4 (not a triad)
        %w[M2 P5]    # sus2 (not a triad)
      ]

      trichord_intervals.each do |intervals|
        trichord_pitches = [root_pitch]
        valid = true

        # Each interval is FROM THE ROOT, not consecutive
        intervals.each do |interval_name|
          interval = HeadMusic::Analysis::DiatonicInterval.get(interval_name)
          next_pitch = interval.above(root_pitch)
          if next_pitch.nil?
            valid = false
            break
          end
          trichord_pitches << next_pitch
        end

        next unless valid

        pitch_set = HeadMusic::Analysis::PitchSet.new(trichord_pitches)
        trichord_pitch_classes = pitch_set.pitch_classes

        # Check if this trichord contains both pitches from our dyad
        if pitch_classes.all? { |pc| trichord_pitch_classes.include?(pc) }
          trichords << pitch_set
        end
      end
    end

    trichords.uniq { |t| t.pitch_classes.sort.map(&:to_i) }
  end

  def generate_possible_seventh_chords
    seventh_chords = []
    pitch_classes = [lower_pitch.pitch_class, upper_pitch.pitch_class]

    # Use all possible spelled root pitches in a middle register
    # Only use single sharps/flats to avoid nil pitch creation issues
    root_spellings = %w[C C# Db D D# Eb E F F# Gb G G# Ab A A# Bb B]

    root_spellings.each do |root_spelling|
      root_pitch = HeadMusic::Rudiment::Pitch.get("#{root_spelling}4")
      next unless root_pitch # Skip if pitch creation failed

      # Try all common seventh chord types from this root
      seventh_chord_intervals = [
        %w[M3 P5 M7],   # major seventh
        %w[M3 P5 m7],   # dominant seventh (major-minor)
        %w[m3 P5 m7],   # minor seventh
        %w[m3 P5 M7],   # minor-major seventh
        %w[m3 d5 m7],   # half-diminished seventh
        %w[m3 d5 d7],   # diminished seventh
        %w[M2 M3 P5 m7], # dominant ninth
        %w[m2 M3 P5 m7], # dominant minor ninth
        %w[M2 m3 P5 m7], # minor ninth
        %w[M2 M3 P5 M7]  # major ninth
      ]

      seventh_chord_intervals.each do |intervals|
        chord_pitches = [root_pitch]
        valid = true

        # Each interval is FROM THE ROOT, not consecutive
        intervals.each do |interval_name|
          interval = HeadMusic::Analysis::DiatonicInterval.get(interval_name)
          next_pitch = interval.above(root_pitch)
          if next_pitch.nil?
            valid = false
            break
          end
          chord_pitches << next_pitch
        end

        next unless valid

        pitch_set = HeadMusic::Analysis::PitchSet.new(chord_pitches)
        chord_pitch_classes = pitch_set.pitch_classes

        # Check if this chord contains both pitches from our dyad
        if pitch_classes.all? { |pc| chord_pitch_classes.include?(pc) }
          seventh_chords << pitch_set
        end
      end
    end

    seventh_chords.uniq { |c| c.pitch_classes.sort.map(&:to_i) }
  end

  def filter_by_key(pitch_sets)
    return pitch_sets unless key

    diatonic_spellings = key.scale.spellings

    pitch_sets.select do |pitch_set|
      pitch_set.pitches.all? { |pitch| diatonic_spellings.include?(pitch.spelling) }
    end
  end

  def sort_by_diatonic_agreement(pitch_sets)
    return pitch_sets unless key

    diatonic_spellings = key.scale.spellings

    pitch_sets.sort_by do |pitch_set|
      # Count how many pitches match diatonic spellings (lower is better for sort)
      diatonic_count = pitch_set.pitches.count { |pitch| diatonic_spellings.include?(pitch.spelling) }
      -diatonic_count # Negative so higher counts come first
    end
  end

  def generate_enharmonic_respellings
    respellings = []

    # Get enharmonic equivalents for each pitch
    pitch1_equivalents = get_enharmonic_equivalents(pitch1)
    pitch2_equivalents = get_enharmonic_equivalents(pitch2)

    # Generate all combinations
    pitch1_equivalents.each do |p1|
      pitch2_equivalents.each do |p2|
        # Skip the original combination
        next if p1.spelling == pitch1.spelling && p2.spelling == pitch2.spelling

        # Create new dyad with same key context
        respellings << self.class.new(p1, p2, key: key)
      end
    end

    respellings
  end

  def get_enharmonic_equivalents(pitch)
    equivalents = [pitch]

    # Get common enharmonic spellings
    pitch_class = pitch.pitch_class
    letter_names = HeadMusic::Rudiment::LetterName.all

    letter_names.each do |letter_name|
      [-2, -1, 0, 1, 2].each do |alteration_cents|
        spelling = HeadMusic::Rudiment::Spelling.get("#{letter_name}#{alteration_sign(alteration_cents)}")
        next unless spelling

        if spelling.pitch_class == pitch_class
          equivalent_pitch = HeadMusic::Rudiment::Pitch.fetch_or_create(spelling, pitch.register)
          equivalents << equivalent_pitch unless equivalents.any? { |p| p.spelling == spelling }
        end
      end
    end

    equivalents
  end

  def alteration_sign(cents)
    case cents
    when -2 then "bb"
    when -1 then "b"
    when 0 then ""
    when 1 then "#"
    when 2 then "##"
    end
  end
end
