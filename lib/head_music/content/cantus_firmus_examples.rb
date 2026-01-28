module HeadMusic
  module Content
    # Sample cantus firmus examples from various pedagogical sources.
    # These are traditional melodies used for teaching counterpoint.
    module CantusFirmusExamples
      FUX = [
        {source: "Fux", tonality: "D dorian", pitches: %w[D F E D G F A G F E D]},
        {source: "Fux", tonality: "E phrygian", pitches: %w[E C D C A3 A G E F E]},
        {source: "Fux", tonality: "F lydian", pitches: %w[F G A F D E F C5 A F G F]},
        {source: "Fux", tonality: "G mixolydian", pitches: %w[G3 C B3 G3 C E D G E C D B3 A3 G3]},
        {source: "Fux", tonality: "A aeolian", pitches: %w[A3 C B3 D C E F E D C B3 A3]},
        {source: "Fux", tonality: "C ionian", pitches: %w[C E F G E A G E F E D C]},
        {source: "Fux", tonality: "C ionian", pitches: %w[C E F E G F E D C]}
      ].freeze

      CLENDINNING = [
        {source: "Clendinning", name: "F major", tonality: "F major", pitches: %w[F3 G3 A3 F3 D3 E3 F3 C4 A3 F3 G3 F3]},
        {source: "Clendinning", name: "D minor", tonality: "D minor", pitches: %w[D3 A3 G3 F3 E3 D3 F3 E3 D3]},
        {source: "Clendinning", name: "C major (treble)", tonality: "C major", pitches: %w[C D F E F G A G E D C]},
        {source: "Clendinning", name: "C major (bass)", tonality: "C major", pitches: %w[C3 E3 F3 G3 E3 A3 G3 E3 F3 E3 D3 C3]}
      ].freeze

      DAVIS_AND_LYBBERT = [
        {source: "Davis & Lybbert", name: "CF 1 in C major", tonality: "C major", pitches: %w[C3 E3 D3 G3 A3 G3 E3 F3 D3 C3]},
        {source: "Davis & Lybbert", name: "CF 2 in C major", tonality: "C major", pitches: %w[C3 D3 E3 G3 A3 F3 E3 D3 C3]},
        {source: "Davis & Lybbert", name: "CF 3 in G major", tonality: "G major", pitches: %w[G3 F#3 G3 E3 D3 B2 C3 D3 B2 A2 G2]},
        {source: "Davis & Lybbert", name: "CF 4 in G major", tonality: "G major", pitches: %w[G2 B2 C3 D3 E3 D3 B2 C3 A2 G2]},
        {source: "Davis & Lybbert", name: "CF 5 in F major", tonality: "F major", pitches: %w[F3 D3 C3 F3 G3 A3 E3 D3 G3 F3]},
        {source: "Davis & Lybbert", name: "CF 6 in A minor", tonality: "A minor", pitches: %w[A2 E3 C3 D3 B2 G2 A2 C3 B2 A2]},
        {source: "Davis & Lybbert", name: "CF 7 in A minor", tonality: "A minor", pitches: %w[A2 B2 C3 D3 E3 F3 E3 C3 B2 A2]},
        {source: "Davis & Lybbert", name: "CF 8 in E minor", tonality: "E minor", pitches: %w[E3 A3 B3 G3 C4 A3 B3 G3 F#3 E3]},
        {source: "Davis & Lybbert", name: "CF 9 in E minor", tonality: "E minor", pitches: %w[E3 D3 C3 B2 G2 A2 B2 E3 G3 F#3 E3]},
        {source: "Davis & Lybbert", name: "CF 10 in D minor", tonality: "D minor", pitches: %w[D3 F3 E3 G3 F3 D3 A3 G3 F3 E3 D3]}
      ].freeze

      SCHOENBERG = [
        {source: "Schoenberg", tonality: "Eb major", pitches: %w[Eb D G3 Ab3 C Ab3 F3 Eb3]},
        {source: "Schoenberg", tonality: "A major", pitches: %w[A3 C#4 B3 F#3 A3 F#3 G#3 A3]}
      ].freeze

      EXAMPLES = (FUX + CLENDINNING + DAVIS_AND_LYBBERT + SCHOENBERG).freeze

      class << self
        def all
          EXAMPLES
        end

        def by_source(source)
          EXAMPLES.select { |ex| ex[:source] == source }
        end

        def sources
          EXAMPLES.map { |ex| ex[:source] }.uniq
        end
      end
    end
  end
end
