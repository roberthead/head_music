$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec/its'
require 'simplecov'
require 'head_music'

include HeadMusic

if ENV['CIRCLE_ARTIFACTS']
  dir = File.join(ENV['CIRCLE_ARTIFACTS'], 'coverage')
  SimpleCov.coverage_dir(dir)
end
SimpleCov.start

class HeadMusic::Style::Annotation
  def marks_count
    marks_array.length
  end

  def first_mark_code
    first_mark.code if first_mark
  end

  def first_mark
    marks_array.first
  end

  def marks_array
    [marks].flatten.compact
  end
end

def fux_cantus_firmus_examples
  @fux_cantus_firmus_examples ||= [
    { name: 'Fux CF in D', key: 'D dorian', pitches: %w[D F E D G F A G F E D] },
    { name: 'Fux CF in E', key: 'E phrygian', pitches: %w[E C D C A3 A G E F E] },
    { name: 'Fux CF in F', key: 'F lydian', pitches: %w[F G A F D E F C5 A F G F] },
    { name: 'Fux CF in G', key: 'G mixolydian', pitches: %w[G3 C B3 G3 C E D G E C D B3 A3 G3] },
    { name: 'Fux CF in A', key: 'A aeolian', pitches: %w[A3 C B3 D C E F E D C B3 A3] },
    { name: 'Fux CF in C', key: 'C ionian', pitches: %w[C E F G E A G E F E D C] },
    { name: 'Fux CF in C (short)', key: 'C ionian', pitches: %w[C E F E G F E D C] },
  ]
end

def theory_and_analysis_cantus_firmus_examples
  @theory_and_analysis_cantus_firmus_examples ||= [
    { name: 'Clendinning CF in F major', key: 'F major', pitches: %w[F E C D F G F E F A E F] },
    { name: 'Clendinning CF in D minor', key: 'D minor', pitches: %w[D3 A3 G3 F3 E3 D3 F3 E3 D3] },
    { name: 'Clendinning CF in C major (treble)', key: 'C major', pitches: %w[C D F E F G A G E D C] },
    { name: 'Clendinning CF in C major (bass)', key: 'C major', pitches: %w[C3 E3 F3 G3 E3 A3 G3 E3 F3 E3 D3 C3] },
  ]
end

def schoenberg_cantus_firmus_examples
  @schoenberg_cantus_firmus_examples ||= [
    { name: 'Schoenberg CF in Eb major', key: 'Eb major', pitches: %w[Eb D G3 Ab3 C Ab3 F3 Eb3] },
    { name: 'Schoenberg CF in A major', key: 'A major', pitches: %w[A3 C#4 B3 F#3 A3 F#3 G#3 A3] },
  ]
end

def davis_and_lybbert_cantus_firmus_examples
  @davis_and_lybbert_cantus_firmus_examples ||= [
    { name: 'Davis CF 1 in C major', key: 'C major', pitches: %w[C3 E3 D3 G3 A3 G3 E3 F3 D3 C3] },
    { name: 'Davis CF 2 in C major', key: 'C major', pitches: %w[C3 D3 E3 G3 A3 F3 E3 D3 C3] },
    { name: 'Davis CF 3 in G major', key: 'G major', pitches: %w[G3 F#3 G3 E3 D3 B2 C3 D3 B2 A2 G2] },
    { name: 'Davis CF 4 in G major', key: 'G major', pitches: %w[G2 B2 C3 D3 E3 D3 B2 C3 A2 G2] },
    { name: 'Davis CF 5 in F major', key: 'F major', pitches: %w[F3 D3 C3 F3 G3 A3 E3 D3 G3 F3] },
    { name: 'Davis CF 6 in A minor', key: 'A minor', pitches: %w[A2 E3 C3 D3 B2 G2 A2 C3 B2 A2] },
    { name: 'Davis CF 7 in A minor', key: 'A minor', pitches: %w[A2 B2 C3 D3 E3 F3 E3 C3 B2 A2] },
    { name: 'Davis CF 8 in E minor', key: 'E minor', pitches: %w[E3 A3 B3 G3 C4 A3 B3 G3 F#3 E3] },
    { name: 'Davis CF 9 in E minor', key: 'E minor', pitches: %w[E3 D3 C3 B2 G2 A2 B2 E3 G3 F#3 E3] },
    { name: 'Davis CF 10 in D minor', key: 'D minor', pitches: %w[D3 F3 E3 G3 F3 D3 A3 G3 F3 E3 D3] },
  ]
end

def fux_cantus_firmus_examples_with_errors
  [
    {
      name: 'Fux CF in D with a repeated note',
      key: 'D dorian', pitches: %w[D F E D G F F A G F E D],
      expected_message: 'Always move to a different note.'
    },
    {
      name: 'Fux CF in C with too few notes',
      key: 'C ionian', pitches: %w[C E F G E D C],
      expected_message: 'Write at least eight notes.'
    },
    {
      name: 'Fux CF in C with dissonant climax',
      key: 'C ionian', pitches: %w[C E F E B A G F E D C],
      expected_message: 'Peak on a consonant high or low note one time or twice with a step between.'
    },
    {
      name: 'Fux CF in D with chromatic notes added',
      key: 'D dorian', pitches: %w[D F# E D G F# A G F# E D],
      expected_message: 'Use only notes in the key signature.'
    },
    {
      name: 'Fux CF in D ending on third scale degree',
      key: 'D dorian', pitches: %w[D F E D G F A G F],
      expected_message: 'End on the first scale degree.'
    },
    {
      name: 'Fux CF in C with direction change removed',
      key: 'C ionian', pitches: %w[C E F G F E D C],
      expected_message: 'Change melodic direction frequently.'
    },
    {
      name: 'Fux CF in D with two octave leaps added',
      key: 'D dorian', pitches: %w[D F F5 E5 D5 D A G F A G F E D],
      expected_message: 'Use a maximum of one octave leap.'
    },
    {
      name: 'Fux CF in G with less conjunct motion',
      key: 'G mixolydian', pitches: %w[G3 C B3 G3 C E D G E C D A3 G3],
      expected_message: 'Use mostly conjunct motion.'
    },
    {
      name: 'Fux CF in D with reset added',
      key: 'D dorian', pitches: ['D', 'F', 'E', 'D', 'G', 'F', 'A', nil, 'G', 'F', 'E', 'D'],
      expected_message: 'Place a note in each measure.'
    },
    {
      name: 'Fux CF in D with unrecovered large leap',
      key: 'D dorian', pitches: %w[D F E D G A G F E D],
      expected_message: 'Recover large leaps by step in the opposite direction.'
    },
    {
      name: 'Fux CF in A with non-singable interval',
      key: 'A aeolian', pitches: %w[A3 C B3 F E D C B3 A3],
      expected_message: 'Use only PU, m2, M2, m3, M3, P4, P5, m6 (ascending), P8 in the melodic line.'
    },
    {
      name: 'Fux CF in G with non-singable range',
      key: 'G mixolydian', pitches: %w[G3 C B3 G3 G4 F D5 C5 G E C D B3 A3 G3],
      expected_message: 'Limit melodic range to a 10th.'
    },
    {
      name: 'Fux CF in A starting on 5th scale degree',
      key: 'A aeolian', pitches: %w[E C B3 D C E F E D C B3 A3],
      expected_message: 'Start on the first scale degree.'
    },
    {
      name: 'Fux CF in D skipping down to final note',
      key: 'D dorian', pitches: %w[D F E D G F A G F D],
      expected_message: 'Step down to the final note.'
    },
    {
      name: 'Fux CF in G with too many notes',
      key: 'G mixolydian', pitches: %w[G3 C B3 G3 C E D G E C D C B3 A3 G3],
      expected_message: 'Write up to fourteen notes.'
    },
  ]
end
