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
