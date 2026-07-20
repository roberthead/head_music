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

  TRICHORD_INTERVALS = [
    %w[M3 P5],   # major triad
    %w[m3 P5],   # minor triad
    %w[m3 d5],   # diminished triad
    %w[M3 A5],   # augmented triad
    %w[P4 P5],   # sus4 (not a triad)
    %w[M2 P5]    # sus2 (not a triad)
  ].freeze

  SEVENTH_CHORD_INTERVALS = [
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
  ].freeze

  def generate_possible_trichords
    generate_possible_chords(TRICHORD_INTERVALS)
  end

  def generate_possible_seventh_chords
    generate_possible_chords(SEVENTH_CHORD_INTERVALS)
  end

  def generate_possible_chords(interval_sets)
    candidate_chords(interval_sets)
      .select { |chord| includes_dyad?(chord) }
      .uniq { |chord| chord.pitch_classes.sort.map(&:to_i) }
  end

  def candidate_chords(interval_sets)
    candidate_roots.flat_map do |root_pitch|
      interval_sets.map { |intervals| build_chord(root_pitch, intervals) }
    end
  end

  def candidate_roots
    HeadMusic::Rudiment::Spelling::CHROMATIC_SPELLINGS.map do |root_spelling|
      HeadMusic::Rudiment::Pitch.get("#{root_spelling}4")
    end
  end

  def build_chord(root_pitch, intervals)
    chord_pitches = [root_pitch] + intervals.map do |name|
      HeadMusic::Analysis::DiatonicInterval.get(name).above(root_pitch)
    end
    HeadMusic::Analysis::PitchCollection.new(chord_pitches)
  end

  def includes_dyad?(pitch_collection)
    dyad_pitch_classes.all? { |pitch_class| pitch_collection.pitch_classes.include?(pitch_class) }
  end

  def dyad_pitch_classes
    @dyad_pitch_classes ||= [lower_pitch.pitch_class, upper_pitch.pitch_class]
  end

  def filter_by_key(pitch_collections)
    return pitch_collections unless key

    pitch_collections.select do |pitch_collection|
      pitch_collection.pitches.all? { |pitch| diatonic_spellings.include?(pitch.spelling) }
    end
  end

  def sort_by_diatonic_agreement(pitch_collections)
    return pitch_collections unless key

    pitch_collections.sort_by do |pitch_collection|
      -pitch_collection.pitches.count { |pitch| diatonic_spellings.include?(pitch.spelling) }
    end
  end

  def diatonic_spellings
    @diatonic_spellings ||= key.scale.spellings
  end

  def generate_enharmonic_respellings
    lower_equivalents = enharmonic_equivalents_for(pitch1)
    upper_equivalents = enharmonic_equivalents_for(pitch2)

    lower_equivalents.product(upper_equivalents)
      .reject { |lower, upper| original_spelling?(lower, upper) }
      .map { |lower, upper| self.class.new(lower, upper, key: key) }
  end

  def original_spelling?(lower, upper)
    lower.spelling == pitch1.spelling && upper.spelling == pitch2.spelling
  end

  ALTERATION_SIGNS = {-2 => "bb", -1 => "b", 0 => "", 1 => "#", 2 => "##"}.freeze

  def enharmonic_equivalents_for(pitch)
    equivalent_pitches = enharmonic_spellings_for(pitch.pitch_class).map do |spelling|
      HeadMusic::Rudiment::Pitch.fetch_or_create(spelling, pitch.register)
    end
    [pitch, *equivalent_pitches].uniq(&:spelling)
  end

  def enharmonic_spellings_for(target_pitch_class)
    all_spellings.select { |spelling| spelling.pitch_class == target_pitch_class }
  end

  def all_spellings
    HeadMusic::Rudiment::LetterName.all.flat_map do |letter_name|
      ALTERATION_SIGNS.each_value.map { |sign| HeadMusic::Rudiment::Spelling.get("#{letter_name}#{sign}") }
    end.compact
  end
end
