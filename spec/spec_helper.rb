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
    { key: 'D dorian', pitches: %w[D F E D G F A G F E D] },
    { key: 'E phrygian', pitches: %w[E C D C A3 A G E F E] },
    { key: 'F lydian', pitches: %w[F G A F D E F C5 A F G F] },
    { key: 'G mixolydian', pitches: %w[G3 C B3 G3 C E D G E C D B3 A3 G3] },
    { key: 'A aeolian', pitches: %w[A3 C B3 D C E F E D C B3 A3] },
    { key: 'C ionian', pitches: %w[C E F G E A G E F E D C] },
    { key: 'C ionian', pitches: %w[C E F E G F E D C] },
  ]
end

def theory_and_analysis_cantus_firmus_examples
  @theory_and_analysis_cantus_firmus_examples ||= [
    { key: 'F major', pitches: %w[F E C D F G F E F A E F] },
    { key: 'D minor', pitches: %w[D3 A3 G3 F3 E3 D3 F3 E3 D3] },
    { key: 'C major', pitches: %w[C D F E F G A G E D C] },
    { key: 'C major', pitches: %w[C3 E3 F3 G3 E3 A3 G3 E3 F3 E3 D3 C3] },
  ]
end

def schoenberg_cantus_firmus_examples
  @schoenberg_cantus_firmus_examples ||= [
    { key: 'Eb major', pitches: %w[Eb D G3 Ab3 C Ab3 F3 Eb3] },
    { key: 'A major', pitches: %w[A3 C#4 B3 F#3 A3 F#3 G#3 A3] },
  ]
end

def davis_and_lybbert_cantus_firmus_examples
  @davis_and_lybbert_cantus_firmus_examples ||= [
    { key: 'C major', pitches: %w[C3 E3 D3 G3 A3 G3 E3 F3 D3 C3] },
    { key: 'C major', pitches: %w[C3 D3 E3 G3 A3 F3 E3 D3 C3] },
    { key: 'G major', pitches: %w[G3 F#3 G3 E3 D3 B2 C3 D3 B2 A2 G2] },
    { key: 'G major', pitches: %w[G2 B2 C3 D3 E3 D3 B2 C3 A2 G2] },
    { key: 'F major', pitches: %w[F3 D3 C3 F3 G3 A3 E3 D3 G3 F3] },

    { key: 'A minor', pitches: %w[A2 E3 C3 D3 B2 G2 A2 C3 B2 A2] },
    { key: 'A minor', pitches: %w[A2 B2 C3 D3 E3 F3 E3 C3 B2 A2] },
    { key: 'E minor', pitches: %w[E3 A3 B3 G3 C4 A3 B3 G3 F#3 E3] },
    { key: 'E minor', pitches: %w[E3 D3 C3 B2 G2 A2 B2 E3 G3 F#3 E3] },
    { key: 'D minor', pitches: %w[D3 F3 E3 G3 F3 D3 A3 G3 F3 E3 D3] },
  ]
end

def fux_cantus_firmus_examples_with_errors
  [
    { key: 'D dorian', pitches: %w[D F E D G F F A G F E D], modification: 'has a repeated note', expected_message: 'Always move to a different note.' },
    { key: 'C ionian', pitches: %w[C E F G E D C], modification: 'too few notes', expected_message: 'Write at least eight notes.' },
    { key: 'C ionian', pitches: %w[C E F E B A G F E D C], modification: 'climax not consonant', expected_message: 'Peak on a consonant high or low note one time or twice with a step between.' },
    { key: 'D dorian', pitches: %w[D F# E D G F# A G F# E D], modification: 'chromatic notes added', expected_message: 'Use only notes in the key signature.' },
    { key: 'D dorian', pitches: %w[D F E D G F A G F], modification: 'ends on third scale degree', expected_message: 'End on the first scale degree.' },
    { key: 'C ionian', pitches: %w[C E F G F E D C], modification: 'direction change removed', expected_message: 'Change melodic direction frequently.' },
    { key: 'D dorian', pitches: %w[D F F5 E5 D5 D A G F A G F E D], modification: 'two octave leaps added', expected_message: 'Use a maximum of one octave leap.' },
    { key: 'G mixolydian', pitches: %w[G3 C B3 G3 C E D G E C D A3 G3], modification: 'less conjunct', expected_message: 'Use mostly conjunct motion.' },
    { key: 'D dorian', pitches: ['D', 'F', 'E', 'D', 'G', 'F', 'A', nil, 'G', 'F', 'E', 'D'], modification: 'rest added', expected_message: 'Place a note in each measure.' },
    { key: 'D dorian', pitches: %w[D F E D G A G F E D], modification: 'unrecovered large leap', expected_message: 'Recover large leaps by step in the opposite direction.' },
    { key: 'A aeolian', pitches: %w[A3 C B3 F E D C B3 A3], modification: 'non-singable interval', expected_message: 'Use only PU, m2, M2, m3, M3, P4, P5, m6 (ascending), P8 in the melodic line.' },
    { key: 'G mixolydian', pitches: %w[G3 C B3 G3 G4 F D5 C5 G E C D B3 A3 G3], modification: 'non-singable range', expected_message: 'Limit melodic range to a 10th.' },
    { key: 'A aeolian', pitches: %w[E C B3 D C E F E D C B3 A3], modification: 'starts on 5th scale degree', expected_message: 'Start on the first scale degree.' },
    { key: 'D dorian', pitches: %w[D F E D G F A G F D], modification: 'skips down to final note', expected_message: 'Step down to the final note.' },
    { key: 'G mixolydian', pitches: %w[G3 C B3 G3 C E D G E C D C B3 A3 G3], modification: 'too many notes', expected_message: 'Write up to fourteen notes.' },
  ]
end
