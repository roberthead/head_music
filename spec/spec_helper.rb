$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "simplecov"

SimpleCov.start do
  skip "/spec/"
  skip "/vendor/"

  # Set minimum coverage threshold
  minimum_coverage 90

  # Enable different coverage metrics
  enable_coverage :branch

  # Add groups for better organization
  group "Analysis", "lib/head_music/analysis"
  group "Content", "lib/head_music/content"
  group "Instruments", "lib/head_music/instruments"
  group "Rudiments", "lib/head_music/rudiment"
  group "Style", "lib/head_music/style"

  # Refuse coverage drops below threshold
  maximum_coverage_drop 1.0 # 1% drop allowed
end

require "rspec/its"
require "head_music"
require "flow_context"

Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |file| require file }

# Matcher for a GuideItem -- a guideline paired with a guide's configuration,
# e.g. MinimumNotes.with(5).
module ConfiguredGuidelineHelper
  def configured(guideline, **config)
    an_object_having_attributes(guideline: guideline, config: config)
  end

  # The guidelines a guide enforces, whatever tier each sits in and whatever
  # configuration it carries. Most guide specs care only that a guideline is
  # present at all.
  def guidelines_of(guide)
    guide.guide_items.map(&:guideline)
  end
end

# Matcher for a guide wrapped by Guides::Base.with(...), e.g. a contour entry
# in the Style::Guide registry. The reader name differs from the guideline
# matcher (guide_class, not guideline_class) so neither can match the other.
module ConfiguredGuideHelper
  def configured_guide(guide_class, **options)
    an_object_having_attributes(guide_class: guide_class, options: options)
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.include ConfiguredGuidelineHelper
  config.include ConfiguredGuideHelper
end

class HeadMusic::Style::Guideline
  def marks_count
    marks_array.length
  end

  def first_mark_code
    first_mark&.code
  end

  def first_mark
    marks_array.first
  end

  def marks_array
    [marks].flatten.compact
  end
end

FUX_CANTUS_FIRMUS_EXAMPLES = [
  {source: "Fux", key: "D dorian", pitches: %w[D F E D G F A G F E D]},
  {source: "Fux", key: "E phrygian", pitches: %w[E C D C A3 A G E F E]},
  {source: "Fux", key: "F lydian", pitches: %w[F G A F D E F C5 A F G F]},
  {source: "Fux", key: "G mixolydian", pitches: %w[G3 C B3 G3 C E D G E C D B3 A3 G3]},
  {source: "Fux", key: "A aeolian", pitches: %w[A3 C B3 D C E F E D C B3 A3]},
  {source: "Fux", key: "C ionian", pitches: %w[C E F G E A G E F E D C]},
  {source: "Fux", key: "C ionian", pitches: %w[C E F E G F E D C]}
].freeze

def fux_cantus_firmus_examples
  @fux_cantus_firmus_examples ||=
    FUX_CANTUS_FIRMUS_EXAMPLES.map { |params| FlowContext.from_cantus_firmus_params(params) }
end

CLENDINNING_CANTUS_FIRMUS_EXAMPLES = [
  {
    source: "Clendinning", name: "Clendinning F major", key: "F major",
    pitches: %w[F3 G3 A3 F3 D3 E3 F3 C4 A3 F3 G3 F3]
  },
  {
    source: "Clendinning", name: "Clendinning D minor", key: "D minor",
    pitches: %w[D3 A3 G3 F3 E3 D3 F3 E3 D3]
  },
  {
    source: "Clendinning", name: "Clendinning C major (treble)", key: "C major",
    pitches: %w[C D F E F G A G E D C]
  },
  {
    source: "Clendinning", name: "Clendinning C major (bass)", key: "C major",
    pitches: %w[C3 E3 F3 G3 E3 A3 G3 E3 F3 E3 D3 C3]
  }
].freeze

def clendinning_cantus_firmus_examples
  @clendinning_cantus_firmus_examples ||=
    CLENDINNING_CANTUS_FIRMUS_EXAMPLES.map { |params| FlowContext.from_cantus_firmus_params(params) }
end

def schoenberg_cantus_firmus_examples
  @schoenberg_cantus_firmus_examples ||= [
    {source: "Schoenberg", key: "Eb major", pitches: %w[Eb D G3 Ab3 C Ab3 F3 Eb3]},
    {source: "Schoenberg", key: "A major", pitches: %w[A3 C#4 B3 F#3 A3 F#3 G#3 A3]}
  ].map { |params| FlowContext.from_cantus_firmus_params(params) }
end

DAVIS_AND_LYBBERT_CANTUS_FIRMUS_EXAMPLES = [
  {
    source: "Davis & Lybbert", name: "Davis CF 1 in C major", key: "C major",
    pitches: %w[C3 E3 D3 G3 A3 G3 E3 F3 D3 C3]
  },
  {
    source: "Davis & Lybbert", name: "Davis CF 2 in C major", key: "C major",
    pitches: %w[C3 D3 E3 G3 A3 F3 E3 D3 C3]
  },
  {
    source: "Davis & Lybbert", name: "Davis CF 3 in G major", key: "G major",
    pitches: %w[G3 F#3 G3 E3 D3 B2 C3 D3 B2 A2 G2]
  },
  {
    source: "Davis & Lybbert", name: "Davis CF 4 in G major", key: "G major",
    pitches: %w[G2 B2 C3 D3 E3 D3 B2 C3 A2 G2]
  },
  {
    source: "Davis & Lybbert", name: "Davis CF 5 in F major", key: "F major",
    pitches: %w[F3 D3 C3 F3 G3 A3 E3 D3 G3 F3]
  },
  {
    source: "Davis & Lybbert", name: "Davis CF 6 in A minor", key: "A minor",
    pitches: %w[A2 E3 C3 D3 B2 G2 A2 C3 B2 A2]
  },
  {
    source: "Davis & Lybbert", name: "Davis CF 7 in A minor", key: "A minor",
    pitches: %w[A2 B2 C3 D3 E3 F3 E3 C3 B2 A2]
  },
  {
    source: "Davis & Lybbert", name: "Davis CF 8 in E minor", key: "E minor",
    pitches: %w[E3 A3 B3 G3 C4 A3 B3 G3 F#3 E3]
  },
  {
    source: "Davis & Lybbert", name: "Davis CF 9 in E minor", key: "E minor",
    pitches: %w[E3 D3 C3 B2 G2 A2 B2 E3 G3 F#3 E3]
  },
  {
    source: "Davis & Lybbert", name: "Davis CF 10 in D minor", key: "D minor",
    pitches: %w[D3 F3 E3 G3 F3 D3 A3 G3 F3 E3 D3]
  }
].freeze

def davis_and_lybbert_cantus_firmus_examples
  @davis_and_lybbert_cantus_firmus_examples ||=
    DAVIS_AND_LYBBERT_CANTUS_FIRMUS_EXAMPLES.map { |params| FlowContext.from_cantus_firmus_params(params) }
end

FUX_CANTUS_FIRMUS_EXAMPLES_WITH_ERRORS = [
  {
    name: "Fux D with a repeated note",
    key: "D dorian", pitches: %w[D F E D G F F A G F E D],
    expected_message: "Always move to a different note."
  },
  {
    name: "Fux C with too few notes",
    key: "C ionian", pitches: %w[C E F G E D C],
    expected_message: "Write at least eight notes."
  },
  {
    name: "Fux C with dissonant climax",
    key: "C ionian", pitches: %w[C E F E B A G F E D C],
    expected_message: "Peak on a note that is consonant with the tonic."
  },
  {
    name: "Fux D with chromatic notes added",
    key: "D dorian", pitches: %w[D F# E D G F# A G F# E D],
    expected_message: "Use only notes in the key signature."
  },
  {
    name: "Fux D ending on third scale degree",
    key: "D dorian", pitches: %w[D F E D G F A G F],
    expected_message: "End on the first scale degree."
  },
  {
    name: "Fux C with direction change removed",
    key: "C ionian", pitches: %w[C E F G F E D C],
    expected_message: "Change melodic direction frequently."
  },
  {
    name: "Fux D with two octave leaps added",
    key: "D dorian", pitches: %w[D F F5 E5 D5 D A G F A G F E D],
    expected_message: "Use a maximum of one octave leap."
  },
  {
    name: "Fux G with less conjunct motion",
    key: "G mixolydian", pitches: %w[G3 C B3 G3 C E D G E C D A3 G3],
    expected_message: "Use mostly conjunct motion."
  },
  {
    name: "Fux D with reset added",
    key: "D dorian", pitches: ["D", "F", "E", "D", "G", "F", "A", nil, "G", "F", "E", "D"],
    expected_message: "Place a note in each measure."
  },
  {
    name: "Fux D with one measure of half notes",
    key: "D dorian", pitches: %w[D F E D G F A G F E D],
    durations: %i[whole whole whole half half whole],
    expected_message: "Use the same rhythmic value throughout."
  },
  {
    name: "Fux D with unrecovered large leap",
    key: "D dorian", pitches: %w[D F E D G A G F E D],
    expected_message: "Recover large leaps by step in the opposite direction."
  },
  {
    name: "Fux A with non-singable interval",
    key: "A aeolian", pitches: %w[A3 C B3 F E D C B3 A3],
    expected_message: "Use only P1, m2, M2, m3, M3, P4, P5, m6 (ascending), P8 in the melodic line."
  },
  {
    name: "Fux G with non-singable range",
    key: "G mixolydian", pitches: %w[G3 C B3 G3 G4 F D5 C5 G E C D B3 A3 G3],
    expected_message: "Limit melodic range to a tenth."
  },
  {
    name: "Fux A starting on 5th scale degree",
    key: "A aeolian", pitches: %w[E C B3 D C E F E D C B3 A3],
    expected_message: "Start on the first scale degree."
  },
  {
    name: "Fux D skipping down to final note",
    key: "D dorian", pitches: %w[D F E D G F A G F D],
    expected_message: "Step down to the final note."
  },
  {
    name: "Fux G with too many notes",
    key: "G mixolydian", pitches: %w[G3 C B3 G3 C E D G E C D C B3 A3 G3],
    expected_message: "Write up to fourteen notes."
  }
].freeze

def fux_cantus_firmus_examples_with_errors
  FUX_CANTUS_FIRMUS_EXAMPLES_WITH_ERRORS.map { |params| FlowContext.from_cantus_firmus_params(params) }
end

FUX_FIRST_SPECIES_EXAMPLES = [
  {
    source: "Fux chapter one figure 5",
    key: "D dorian",
    cantus_firmus_pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4],
    counterpoint_pitches: %w[A A G A B C5 C5 B D5 C#5 D5]
  },
  {
    source: "fux chapter one figure 6 (with errors)",
    key: "D dorian",
    cantus_firmus_pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4],
    counterpoint_pitches: %w[G3 D A3 F3 E3 D3 F3 C D C# D],
    expected_message: "Start on the tonic or a perfect consonance above the tonic (unless bass voice)."
  },
  {
    source: "fux chapter one figure 6 (corrected)",
    key: "D dorian",
    cantus_firmus_pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4],
    counterpoint_pitches: %w[D3 D3 A3 F3 E3 D3 F3 C D C# D]
  },
  {
    source: "fux chapter one figure 11",
    key: "E phrygian",
    cantus_firmus_pitches: %w[E C D C A3 A4 G E F E],
    counterpoint_pitches: %w[B C5 F G A C5 B E5 D5 E5]
  },
  {
    source: "fux chapter one figure 12 (with errors)",
    key: "E phrygian",
    cantus_firmus_pitches: %w[E C D C A3 A4 G E F E],
    counterpoint_pitches: %w[E3 A3 D3 E3 F3 F3 B3 C4 D4 E4],
    expected_message: "Use only P1, m2, M2, m3, M3, P4, P5, m6 (ascending), P8 in the melodic line."
  },
  {
    source: "fux chapter one figure 12 (corrected)",
    key: "E phrygian",
    cantus_firmus_pitches: %w[E C D C A3 A4 G E F E],
    counterpoint_pitches: %w[E3 A3 D3 E3 F3 F3 C4 C4 D4 E4]
  },
  {
    source: "fux chapter one figure 13",
    key: "F lydian",
    counterpoint_pitches: %w[F E C F F G A G C F E F],
    cantus_firmus_pitches: %w[F3 G3 A3 F3 D3 E3 F3 C4 A3 F3 G3 F3]
  },
  {
    source: "fux chapter one figure 14",
    key: "F ionian",
    cantus_firmus_pitches: %w[F3 G3 A3 F3 D3 E3 F3 C4 A3 F3 G3 F3],
    counterpoint_pitches: %w[F3 E3 F3 A3 Bb3 G3 A3 E3 F3 D3 E3 F3]
  },
  {
    source: "fux chapter one figure 15 (with errors)",
    key: "G mixolydian",
    counterpoint_pitches: %w[G4 E4 D4 G4 G4 G4 A4 B4 G4 E5 D5 G4 F#4 G4],
    cantus_firmus_pitches: %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4 B3 A3 G3],
    expected_message: "Use only P1, m2, M2, m3, M3, P4, P5, m6 (ascending), P8 in the melodic line."
  },
  {
    source: "fux chapter one figure 15 (corrected)",
    key: "G mixolydian",
    counterpoint_pitches: %w[G4 E4 D4 G4 G4 G4 A4 B4 G4 C5 A4 G4 F#4 G4],
    cantus_firmus_pitches: %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4 B3 A3 G3]
  },
  {
    source: "Fux chapter one figure 21",
    key: "G ionian",
    cantus_firmus_pitches: %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4 B3 A3 G3],
    counterpoint_pitches: %w[G3 A3 G3 E3 E3 C3 G3 B3 C4 A3 F#3 G3 F#3 G3]
  },
  {
    source: "Fux chapter one figure 22",
    key: "A aeolian",
    counterpoint_pitches: %w[A4 E4 G4 F4 E4 C5 A4 B4 B4 A4 G#4 A4],
    cantus_firmus_pitches: %w[A3 C4 B3 D4 C4 E4 F4 E4 D4 C4 B3 A3]
  },
  {
    source: "Fux chapter one figure 23",
    key: "A aeolian",
    cantus_firmus_pitches: %w[A3 C4 B3 D4 C4 E4 F4 E4 D4 C4 B3 A3],
    counterpoint_pitches: %w[A3 A3 G3 F3 E3 E3 D3 C3 G3 A3 G#3 A3]
  }
].freeze

def fux_first_species_examples
  FUX_FIRST_SPECIES_EXAMPLES.map { |params| FlowContext.from_params(params) }
end

# The diminution species, each set above the D dorian cantus firmus that opens
# every chapter of Gradus, so that grading one against another compares rhythm
# rather than cantus. Figure numbers follow Mann's translation; the notes were
# checked against the kern transcriptions in MarkGotham/species. In ABC, `d` is
# D5 and `A` is A4, and a tie across the bar line is written as Fux wrote it.
# Figures 33 and 55 open on the downbeat, as printed; only 73 and 82 enter
# after a half rest.
# Fux's cantus firmi keyed by ABC key, in the register of the Gradus scan.
# Lydian sits an octave below the F4 of FUX_CANTUS_FIRMUS_EXAMPLES.
FUX_CANTUS_FIRMUS_ABC = {
  "Ddor" => "D4|F4|E4|D4|G4|F4|A4|G4|F4|E4|D4|]",
  "Ephr" => "E4|C4|D4|C4|A,4|A4|G4|E4|F4|E4|]",
  "Flyd" => "F,4|G,4|A,4|F,4|D,4|E,4|F,4|C4|A,4|F,4|G,4|F,4|]",
  "Gmix" => "G,4|C4|B,4|G,4|C4|E4|D4|G4|E4|C4|D4|B,4|A,4|G,4|]",
  "Aaeo" => "A,4|C4|B,4|D4|C4|E4|F4|E4|D4|C4|B,4|A,4|]",
  "Cion" => "C4|D4|F4|E4|G4|F4|E4|D4|C4|]"
}.freeze

def species_abc(params)
  key = params.fetch(:key, "Ddor")
  <<~ABC
    X:1
    T:#{params.fetch(:source)}
    M:#{params.fetch(:meter, "4/4")}
    L:1/4
    K:#{key}
    V:cantus firmus
    #{params.fetch(:cantus_firmus) { FUX_CANTUS_FIRMUS_ABC.fetch(key) }}
    V:counterpoint
    #{params.fetch(:counterpoint)}
  ABC
end

def species_examples(params_list)
  params_list.map { |params| FlowContext.from_abc(params.merge(abc: species_abc(params))) }
end

FUX_SECOND_SPECIES_EXAMPLES = [
  {
    source: "Fux chapter two figure 33",
    counterpoint: "A2 d2|A2 B2|c2 G2|A2 d2|B2 c2|d2 A2|c2 d2|e2 B2|d2 A2|B2 ^c2|d4|]"
  }
].freeze

def fux_second_species_examples
  species_examples(FUX_SECOND_SPECIES_EXAMPLES)
end

FUX_THIRD_SPECIES_EXAMPLES = [
  {
    source: "Fux chapter three figure 55",
    counterpoint: "D E F G|A B c d|e d B c|d c _B A|_B c d e|f F A B|c A _B c|_B A G _B|A D E F|G A B ^c|d4|]"
  }
].freeze

def fux_third_species_examples
  species_examples(FUX_THIRD_SPECIES_EXAMPLES)
end

# Not in Gradus, which has no triple-meter species. Built on Fux's D dorian
# cantus firmus so it sits in the same matrix as the figures above.
THIRD_SPECIES_TRIPLE_METER_EXAMPLES = [
  {
    source: "Constructed triple-meter third species on Fux's D dorian cantus firmus",
    meter: "3/4",
    cantus_firmus: "D3|F3|E3|D3|G3|F3|A3|G3|F3|E3|D3|]",
    counterpoint: "z A B|c d e|d c B|A B c|d c B|A B c|c d e|d e d|c d c|B c ^c|d3|]"
  }
].freeze

def third_species_triple_meter_examples
  species_examples(THIRD_SPECIES_TRIPLE_METER_EXAMPLES)
end

FUX_FOURTH_SPECIES_EXAMPLES = [
  {
    source: "Fux chapter four figure 73",
    counterpoint: "z2 A2-|A2 d2-|d2 c2-|c2 _B2-|_B2 G2|A2 c2-|c2 f2-|f2 e2-|e2 d2-|d2 ^c2|d4|]"
  }
].freeze

def fux_fourth_species_examples
  species_examples(FUX_FOURTH_SPECIES_EXAMPLES)
end

# Figures 82 to 88 of Gradus, in Mann's numbering: each mode once with the
# counterpoint above the cantus and once below. Pitches read from the scan and
# confirmed against Mark Gotham's kern transcriptions, except figure 87's upper
# counterpoint, which has no kern.
FUX_FIFTH_SPECIES_EXAMPLES = [
  {
    source: "Fux chapter five figure 82",
    counterpoint: "z2 A2-|A D E F|G F E G|F D d2-|d c _B G|A B c2-|c2 f2-|f e/2 d/2 e2-|e A d2-|d2 ^c2|d4|]"
  },
  {
    source: "Fux chapter five figure 83",
    counterpoint: "z2 D2-|D2 A, B,|C G, C2-|C B,/2 A,/2 B, A,|G, A, B, C|D A, D2-|D E F2-|F E/2 D/2 E2-|E A, D2-|D2 ^C2|D4|]"
  },
  {
    source: "Fux chapter five figure 84a",
    key: "Ephr",
    counterpoint: "z2 e2-|e d c B|A G F D|E G c2-|c B A G|F2 c2-|c B/2 A/2 B A|G E e2-|e2 d2|e4|]"
  },
  {
    source: "Fux chapter five figure 84b",
    key: "Ephr",
    counterpoint: "z2 E,2|A, B, C2-|C B,/2 A,/2 B, G,|A,2 E,2|F, D, F,2-|F, G, A, B,|C B, C2-|C D E2-|E2 D2|E4|]"
  },
  {
    source: "Fux chapter five figure 85a",
    key: "Flyd",
    counterpoint: "z2 F2-|F2 E D|C A, C2-|C A, D2-|D C _B, A,|G,2 C _B,|A,2 A2-|A2 G2|A G F E|D C F2-|F2 E2|F4|]"
  },
  {
    source: "Fux chapter five figure 85b",
    key: "Flyd",
    counterpoint: "z2 F,2-|F, E,/2 D,/2 C, _B,,|A,, G,, F,,2-|F,, A,, _B,,2-|_B,, C, D,2-|D,2 C, _B,,|A,,2 F,2|E,2 F,2-|F, E, D,2|D, E, F,2-|F,2 E,2|F,4|]"
  },
  {
    # The kern drops the tie from bar 11 into bar 12 at the scan's system
    # break; the scan ties them.
    source: "Fux chapter five figure 86a",
    key: "Gmix",
    counterpoint: "z2 G2-|G F E D/2 C/2|D2 G A|B c d B|e d c2-|c B A G|A B/2 c/2 d c|B G B2-|B A G2-|G F E G|^F G A2-|A G G2-|G2 ^F2|G4|]"
  },
  {
    source: "Fux chapter five figure 86b",
    key: "Gmix",
    counterpoint: "z2 G,2|E,2 A,2-|A,2 G, F,|E, C, E,2-|E,2 A,2-|A, B, C2-|C2 B, A,|B,2 E D|C B, A,2-|A, B, C2-|C2 B, A,|G, D, G,2-|G,2 ^F,2|G,4|]"
  },
  {
    source: "Fux chapter five figure 87 upper counterpoint (scan only; no kern transcription)",
    key: "Aaeo",
    counterpoint: "z2 A2-|A2 G A|B G B2-|B2 A B|c G c2-|c B/2 A/2 B c|d A d2-|d c c2-|c B/2 A/2 B2-|B E A2-|A2 ^G2|A4|]"
  },
  {
    source: "Fux chapter five figure 87a",
    key: "Aaeo",
    counterpoint: "z2 A,2-|A, G, E, F,|G, D, G,2-|G, A, B,2-|B,2 A,2-|A, B, C B,|A,2 D2-|D C C2-|C B,/2 A,/2 B,2-|B, E, A,2-|A,2 ^G,2|A,4|]"
  }
].freeze

def fux_fifth_species_examples
  species_examples(FUX_FIFTH_SPECIES_EXAMPLES)
end

def fux_fifth_species_example(figure)
  fux_fifth_species_examples.detect { |context| context.source.end_with?(figure) }
end

CLENDINNING_FIRST_SPECIES_EXAMPLES = [
  {
    source: "Clendinning 3e Ex 9.1",
    key: "F major",
    counterpoint_pitches: %w[F4 E4 C4 D4 F4 G4 F4 E4 F4 A4 E4 F4],
    cantus_firmus_pitches: %w[F3 G3 A3 F3 D3 E3 F3 C4 A3 F3 G3 F3]
  },
  {
    source: "Clendinning 3e Ex 9.2",
    key: "D minor",
    counterpoint_pitches: %w[D5 C5 Bb4 D5 E5 F5 D5 C#5 D5],
    cantus_firmus_pitches: %w[D3 A3 G3 F3 E3 D3 F3 E3 D3]
  },
  # {
  #   source: 'Clendinning 3e p 170',
  #   key: 'C major',
  #   cantus_firmus_pitches: %w[C D  F  E F G A  G  E  D  C],
  #   counterpoint_pitches:  %w[C B3 A3 C D C F3 G3 G3 B3 C],
  # },
  {
    source: "Clendinning 3e Ex 9.4",
    key: "C major",
    cantus_firmus_pitches: %w[C D F E F G A G E D C],
    counterpoint_pitches: %w[C B3 A3 G3 F3 E3 F3 G3 G3 B3 C]
  }
].freeze

def clendinning_first_species_examples
  CLENDINNING_FIRST_SPECIES_EXAMPLES.map { |params| FlowContext.from_params(params) }
end

DAVIS_AND_LYBBERT_FIRST_SPECIES_EXAMPES = [
  {
    source: "Davis and Lybbert first illustration (p 16)",
    key: "C major",
    counterpoint_pitches: %w[G4 G3 A3 B3 C4 D4 E4 A3 B3 C4],
    cantus_firmus_pitches: %w[C3 E3 D3 G3 A3 G3 E3 F3 D3 C3]
  },
  {
    source: "Davis and Lybbert second illustration (p 16)",
    key: "D minor",
    cantus_firmus_pitches: %w[D5 F5 E5 G5 F5 D5 A5 G5 F5 E5 D5],
    counterpoint_pitches: %w[D3 D4 C4 Bb3 A3 Bb3 F3 G3 A3 C#4 D4]
  }
].freeze

def davis_and_lybbert_first_species_examples
  DAVIS_AND_LYBBERT_FIRST_SPECIES_EXAMPES.map { |params| FlowContext.from_params(params) }
end

# Not a counterpoint: the Fux chapter one figure 5 cantus firmus sung again an
# octave up. One line, twice. It breaks the one thing counterpoint is for while
# satisfying most of what a first species guide measures, which is why it
# belongs in the graded corpus rather than only in a spec.
DOUBLED_OCTAVE_EXAMPLES = [
  {
    source: "Fux chapter one figure 5 doubled at the octave",
    key: "D dorian",
    cantus_firmus_pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4],
    counterpoint_pitches: %w[D5 F5 E5 D5 G5 F5 A5 G5 F5 E5 D5]
  }
].freeze

def doubled_octave_examples
  DOUBLED_OCTAVE_EXAMPLES.map { |params| FlowContext.from_params(params) }
end
