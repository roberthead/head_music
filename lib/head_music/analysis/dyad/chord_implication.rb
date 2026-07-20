class HeadMusic::Analysis::Dyad
  # Enumerates the chords (as PitchCollections) that contain a given dyad.
  # Trichords and seventh chords are built at every chromatic root from a fixed
  # table of interval stacks, then kept only when they actually span the dyad.
  # An optional key narrows the results to diatonic chords and ranks the
  # survivors by how many of their pitches the key contains.
  class ChordImplication
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

    attr_reader :dyad_pitch_classes, :key

    def initialize(dyad_pitch_classes, key)
      @dyad_pitch_classes = dyad_pitch_classes
      @key = key
    end

    def trichords
      @trichords ||= ranked(chords_from(TRICHORD_INTERVALS))
    end

    def seventh_chords
      @seventh_chords ||= ranked(chords_from(SEVENTH_CHORD_INTERVALS))
    end

    private

    # Without a key every chord stands; with one, keep the diatonic chords and
    # order them by how much they agree with the key. Concentrating the key
    # check here keeps filter and sort free of their own guards.
    def ranked(chords)
      return chords unless key

      sort_by_diatonic_agreement(filter_by_key(chords))
    end

    def chords_from(interval_sets)
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

    def filter_by_key(pitch_collections)
      pitch_collections.select do |pitch_collection|
        pitch_collection.pitches.all? { |pitch| diatonic_spellings.include?(pitch.spelling) }
      end
    end

    def sort_by_diatonic_agreement(pitch_collections)
      pitch_collections.sort_by do |pitch_collection|
        -pitch_collection.pitches.count { |pitch| diatonic_spellings.include?(pitch.spelling) }
      end
    end

    def diatonic_spellings
      @diatonic_spellings ||= key.scale.spellings
    end
  end
end
