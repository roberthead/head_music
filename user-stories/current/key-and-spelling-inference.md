<!--
metadata:
  created_at:   2026-10-14T15:16:39-07:00
  activated_at: 2026-10-15T21:03:39-07:00
  planned_at:   2026-10-15T21:24:00-07:00
  finished_at:
  updated_at:   2026-10-16T08:22:19-07:00
-->

# Story: Key and Spelling Inference

## Summary

AS a developer or researcher using HeadMusic

I WANT to infer the key of a passage given only key numbers and timing, and to spell each key number as a pitch in that key

SO THAT music that arrives without spelling, such as MIDI, becomes notation a musician can read and the gem's guides can grade

## Background

MIDI records key numbers, not pitches: 61 could be C♯ or D♭. Today `Pitch.get(61)` answers C♯4 and `Pitch.get(70)` answers A♯4, always sharps, whatever the context. That spelling is wrong in flat keys, and it misleads every interval and guideline that reads it. An A♯ where B♭ belongs makes an augmented interval out of a perfect one.

Two inferences repair this, and each is useful alone:

- **Key finding.** Weight each pitch class by how long it sounds, and correlate that profile with the major and minor key profiles. Krumhansl and Kessler's profiles are the classic choice, and Temperley and Aarden offer others. The best correlation names the key. Run over a window that moves through the piece, with a penalty for changing key, it finds modulations.
- **Pitch spelling.** Place spellings on the line of fifths (… B♭ F C G D A E B F♯ C♯ …). Then choose for each key number the spelling nearest the key's center and the spellings around it, as in Temperley's line-of-fifths speller and Meredith's PS13. Melodic direction breaks near-ties: a chromatic note rising to its neighbor is raised, and one falling to its neighbor is lowered.

The rudiments are already there. `Spelling`, `Key`, `KeySignature`, `TonalContext`, and `EnharmonicEquivalence` all exist, and `PitchClassSet` and `Circle` live in `Analysis`.

This story is the prerequisite of [MIDI Import](midi-import.md), and lands before it. It belongs in `HeadMusic::Analysis`, where other callers can use it too: transposition results, pitch-class set realizations, and any `Pitch.get(number)` caller that knows its context.

## Example

```ruby
notes = [[60, "1:1", :quarter], [62, "1:2", :quarter], [63, "1:3", :quarter], [65, "1:4", :quarter], [67, "2:1", :half]]

HeadMusic::Analysis::KeyFinder.new(notes, meter: "4/4").key        # => C minor
# Under profile: :krumhansl_kessler this melody ties G minor and C minor.
HeadMusic::Analysis::PitchSpeller.new(notes, key: "C minor").pitches
# => C4, D4, E♭4, F4, G4
```

The class names and input shape above are a sketch, to be settled in planning.

## Acceptance Criteria

### Input

- [ ] Both inferences take the same input: key numbers with onsets and durations, optionally grouped by voice, so MIDI Import can call them before a flow exists
- [ ] Both also take a flow, reading its pitches as key numbers, so a flow with poor spelling can be respelled
- [ ] Both are deterministic: the same input gives the same answer

### Key finding

- [ ] The key finder answers the major or minor key whose profile correlates best with the duration-weighted pitch-class profile of the input
- [ ] It also answers every candidate key ranked with its correlation, so a caller can see an ambiguous result
- [ ] The key profiles are named and selectable (Aarden–Essen by default, plus Krumhansl–Kessler and Temperley (2007)), and each is documented with its source
- [ ] Inferred keys take the tonic with the fewer accidentals (G♭ major and E♭ minor at six). A later region takes the spelling nearer the previous region's tonic
- [ ] Over a whole piece, the key finder answers key regions, each beginning at a bar's downbeat, since the timeline changes keys only there. A documented penalty for changing key keeps it from switching key every bar
- [ ] Input with no notes answers no key, rather than raising

### Spelling

- [ ] Given a key, the speller spells every key number. When the key is not given, it uses the key finder's regions
- [ ] Every key number in the key's diatonic collection is spelled diatonically. In E♭ major, 63 is E♭ and 68 is A♭
- [ ] The raised leading tone of a minor key is spelled as raised: in A minor, 68 is G♯, and in G♯ minor, 67 is F𝄪
- [ ] A chromatic note follows melodic direction when its two nearest spellings are within 2 fifths of each other and the next note in its voice is a semitone away. Notes given without voices count as one voice when none of them overlaps another; otherwise a note with no voice takes no direction. In C major, 60–61–62 spells C♯ and 62–61–60 spells D♭, 61 and 63 follow direction, and 66 is always F♯ and 70 always B♭
- [ ] Notes sounding together are spelled to keep the sonority in thirds where one spelling does. In F minor, 61–65–68 is D♭–F–A♭, not C♯–F–G♯, and in C major, 61–65–68 sounding alone is D♭–F–A♭
- [ ] For every key from −6 to +6 fifths, each pitch class spelled alone takes at most one accidental, except a minor key's raised 7th (G♯ minor: 67 is F𝄪)
- [ ] Given a Mode, the speller uses the mode's own collection
- [ ] The speller answers, for each note, the rule that decided it (`:diatonic`, `:raised`, `:direction`, `:sonority`, `:center`, `:fallback`), and the chorale spec reports misses by rule
- [ ] Respelling a flow returns a new flow with the same key numbers and timing, and the flow passed in is unchanged. It takes `key:`. By default each bar is spelled by the tonal context in force and the timeline is unchanged. With `key: :infer`, its key signature changes are replaced by ones from the key regions, and a region in the relative key of the one before writes no signature change

### Evaluation

- [ ] The ABC, LilyPond, and kern fixtures, stripped to key numbers, are respelled. Their accuracy against the written spelling is pinned in specs: the note count and every note that differs
- [ ] With `KERN_CORPUS` pointing at the Bach chorales, a spec measures and records spelling accuracy twice: with the key from the file's key signature and designation, and with the key inferred. It also measures how often the inferred key of each chorale agrees with its `*G:`-style designation. The measured figures are recorded in this story and pinned as floors
- [ ] Spelling reaches at least 99.5% of notes on the chorales, with the key given and with the key inferred. In key agreement, a modal designation agrees with its parallel key
- [ ] Accuracy is counted per sounding pitch: each pitch of a chord once, a tied chain once. A spelling is correct when the pitch equals the written one, register included. Grace notes are respelled, take no weight in key finding, and are counted separately. Unpitched sounds are neither weighted nor spelled
- [ ] Maintains 90%+ test coverage

## Notes

- **Major and minor only.** Key-finding profiles exist for major and minor. Modal finding (Dorian, Phrygian, …) needs profiles the literature does not settle, and the Renaissance repertoire that would want it arrives mostly spelled, through kern and MEI. A follow-up could infer the final and mode from cadences instead.
- **No atonal spelling.** Atonal and twelve-tone music is spelled by different conventions, such as sharps rising and flats falling regardless of key. The melodic-direction rule above is a start, but a key-free speller is a follow-up.
- **Deferred: a running center of gravity.** Measured on the chorales at +10 notes of 83,196, which does not justify a tuning parameter. Direction and sonority cover "the spellings around it". The per-rule miss report will show whether non-chorale music wants one.
- **Deferred: a smaller penalty between closely related keys.** No corpus gives the key regions within a piece, so there is nothing to tune it against, and spelling barely moves with the penalty.
- **Measured on the chorales** (2026-10-16, `spec/head_music/analysis/spelling_corpus_spec.rb`, pinned as floors). The 366 readable chorales hold 83,196 sounding pitches and no grace notes.

  | Measure | Correct | Figure |
  |---|---|---|
  | (a) Spelling, key from the signature and designation | 83,150 of 83,196 | 99.945% |
  | (b) Spelling, key inferred | 83,152 of 83,196 | 99.947% |
  | (c) Whole-piece key, major/minor designations | 295 of 319 | 92.5% |
  | (c) Whole-piece key, modal designations (parallel key) | 37 of 47 | 78.7% |
  | (c) Whole-piece key, all | 332 of 366 | 90.7% |
  | (c) First region, major/minor designations | 300 of 319 | 94.0% |
  | (c) First region, modal designations | 39 of 47 | 83.0% |
  | (c) First region, all | 339 of 366 | 92.6% |

  Misses by rule:

  | Rule | (a) Key given | (b) Inferred |
  |---|---|---|
  | `:direction` | 34 | 34 |
  | `:raised` | 7 | 4 |
  | `:center` | 4 | 5 |
  | `:sonority` | 1 | 1 |
  | Total | 46 | 44 |

  Direction dominates: each of its misses is a chromatic note written against the semitone that follows it, such as a D♯ falling to D. The inferred key misses two fewer, mostly in modal chorales, where a minor-like mode's raised 6th and 7th misspell a lowered note: chor034 (E Phrygian) writes E♭ and chor113 (F Dorian) F♭. Two chorales trade a miss: chor216 misses only with the key given, chor314 only inferred. The default penalty finds 388 regions in 366 chorales, 0.06 changes per piece. The corpus measures in about 4.5 s of CPU time on top of 5.6 s of parsing.
- **Risk: a tonic-heavy melody reads as the subdominant under Aarden.** Aarden's major profile weights the fifth above the tonic most, so a melody that dwells on its tonic matches the key a fifth below. The C major scale in eighths, then two bars of a held C (ABC `C2 D2 E2 F2 | G2 A2 B2 c2 | c8 | c8 |` in 4/4, `L:1/8`), finds F major at 0.587, ahead of A minor at 0.491 and C major at 0.481. It is one F major region, and `respell(key: :infer)` writes an F major signature, so every B needs a natural. Krumhansl–Kessler and Temperley both answer C major. The chorales do not show it, so MIDI Import should measure it on its own corpus before relying on `:infer` for signatures.
- `Pitch.get(number)` keeps its sharp spelling. Callers that know their context use the speller.
- Sources to cite in the code: Krumhansl, *Cognitive Foundations of Musical Pitch* (1990); Temperley, *The Cognition of Basic Musical Structures* (2001); Meredith, "The ps13 pitch spelling algorithm," *Journal of New Music Research* 35 (2006).

## Decisions

- **This story is a prerequisite of MIDI Import** (decided 2026-10-14), split out so the inference can serve other callers and be judged on spelled corpora before any MIDI reading exists.
- **It lives in `HeadMusic::Analysis`** (decided 2026-10-14), as the original MIDI Import story suggested.

- **Planning choices adopted without stopping to ask** (2026-10-15, while running the seven-story goal; Rob may revise any). All of the planner's proposed story changes were adopted:
  - **Profiles and regions.** Aarden–Essen is the default profile. Each bar is scored alone, and the key-change penalty is 1.0, which is conservative because regions become key signatures.
  - **Speller precedence.** Collection, then direction, then sonority, then the line-of-fifths center, as measured on the chorales: 47 misses against 65 with sonority first.
  - **Confidence.** It is answered as the deciding rule per note rather than a number, since a number would need calibration no caller asks for.
  - **Enharmonic keys.** The fewer accidentals win, so G♭ major and E♭ minor at six.
  - **Modes** use their own collections.
  - **The 24-key table** is fixed by name, not built through `Key#relative`. `Key#relative` spells the flat side with sharps, and that is fixed as a bug here.

## Implementation Plan

### Overview

The story adds two classes to `HeadMusic::Analysis`, both reading one shared input of unspelled notes:

- **`KeyFinder`** correlates a duration-weighted pitch-class profile with key profiles. For a whole piece it scores each bar, then picks key regions by dynamic programming over bars, paying a penalty for each key change.
- **`PitchSpeller`** places each note on the line of fifths around its region's key center and applies fixed tie-breaks.

A probe on the 366 readable Bach chorales (83,196 sounding pitches) shows the design clears the story's targets easily. With the key from the file it spelled 99.94% correctly; with the key inferred, 99.9%. The probe scripts are in `/private/tmp/claude-501/-Users-roberthead-github-com-roberthead-head-music/32cd5f96-66f9-4ba4-aa1b-0a3786f3fdb9/scratchpad/kasi-plan/`, in `tie_probe2.rb`, `chor_pen.rb` and `inv_probe.rb`.

I consulted the product-manager, developer and best-practices-engineer. The best-practices engineer was brought in because a sliding-window key finder needs real tuning. I skipped the ui-ux-designer and accessibility-specialist because the story has no UI.

**Settled choices (each one argued in the steps):**

- **Default profile:** Aarden–Essen. Krumhansl–Kessler and Temperley are selectable.
- **Region scoring:** each bar is scored alone (window 0), with a change penalty of 1.0.
- **Speller rule order:**
  1. Notes in the key's collection, plus a minor key's raised 6th and 7th, are spelled from it.
  2. Otherwise, when the two nearest spellings are within 2 fifths of each other, the next note in the voice decides.
  3. Then the compactness of notes sounding together decides.
  4. Then the spelling nearest the center wins, the sharper one on an exact tie.
- **No running center of gravity in v1.**
- **Per-note confidence:** each note reports the rule that decided it, not a number.

### Steps

Every step:

- adds its require to `lib/head_music.rb` after `analysis/sonority` (line 237);
- adds a CHANGELOG line under Unreleased ("Added", unless noted otherwise);
- runs `bundle exec rubocop -a`;
- commits with its specs.

0. **Fix `Key#relative` on the flat side** (independent of everything else; can land any time)
   - `key.rb:58-68` adds ±3 semitones to `tonic_pitch`, which spells with sharps. I verified that `Key.get("Eb minor").relative` gives F♯ major and `Key.get("Gb major").relative` gives D♯ minor.
   - Fix it by letter step:
     - relative minor = tonic letter `steps_down(2)`, through `Spelling.from_number_and_letter`;
     - relative major = tonic letter `steps_up(2)`.
   - No step below calls `#relative`, but it is a real bug, and the 24-key table must not be built through it.
   - CHANGELOG under **Fixed**.
   - Specs: E♭ minor ↔ G♭ major, B♭ minor ↔ D♭ major, D♯ minor ↔ F♯ major, G♯ minor ↔ B major.
   - Files: `lib/head_music/rudiment/key.rb`, `spec/head_music/rudiment/key_spec.rb`

1. **The contract: input types and adapters.** Lands first, on dab4eb0b. It is the base commit for worktrees A and B.
   - `UnspelledNote = Data.define(:number, :onset, :duration, :voice)`:
     - `number` is the key number. It is not called `key`, because "key" means the tonality in this story.
     - `onset` and `duration` are Rational whole notes, with the first downbeat at 0. This is the convention MIDI export already uses (`midi/note_timing.rb:11`, `midi/performance_timeline.rb`). MIDI Import gets them as `Rational(tick, 4 * division)` with no flow.
     - `voice` is any hashable label and defaults to nil.
   - `KeyRegion = Data.define(:bar_number, :onset, :key)`.
   - `NoteInput.for(input, meter: nil, bars: nil, first_bar: 1)` accepts:
     - a `NoteInput`;
     - an Array of `UnspelledNote`s;
     - `[number, onset, duration(, voice)]` tuples, where the onset may be a `"bar:count"` string when a uniform `meter:` is given (this keeps the story example working) and the duration anything `RhythmicValue.get` reads;
     - a `Flow`.
   - `NoteInput` answers `#notes` (input order), `#bar_starts`, `#bar_at(onset)` and `#flow`.
   - How bars are known without a flow:
     - `bars:` is a list of downbeat onsets, for meter changes. A pickup is `first_bar: 0`.
     - `meter:` alone gives uniform bars.
     - With neither, the whole input is one bar.
   - The flow adapter:
     - Walks voice events in written order, not `performance_order`, so repeats are not counted twice.
     - Bar starts are summed with `MIDI::PerformanceTimeline.bar_length` (`performance_timeline.rb:32-35`). The offset in the bar comes from `BarSplitter.exact_start` (`notation/bar_splitter.rb:115`).
     - Duration is `rhythmic_value.fraction`, which covers the whole tied chain.
     - It takes pitched sounds only. Grace notes come at the main note's onset with duration 0.
     - It keeps each note's address in `flow.to_h` for respelling in step 8.
     - Pitches are read as stored, at concert pitch (`content/layout/transposition.rb:6`).
   - Specs:
     - tuples, Data and `"bar:count"` input;
     - `bars:` with `first_bar: 0`;
     - a flow across a meter change and a pickup (`LilyPondFixtures`);
     - a tied chain's duration;
     - grace notes at duration 0;
     - rests and unpitched sounds skipped.
   - Files: `lib/head_music/analysis/unspelled_note.rb`, `key_region.rb`, `note_input.rb`; matching specs under `spec/head_music/analysis/`

2. **`KeyProfile`** (worktree A)
   - `KeyProfile = Data.define(:name, :major, :minor, :source)`, with `.get(name)`, `.names`, and `#correlations(histogram)`, which answers all 24 Pearson values.
   - The source citation is in the code. The values run from the tonic upward in semitones:

     | Profile | Major | Minor |
     |---|---|---|
     | `:krumhansl_kessler` (Krumhansl 1990, from Krumhansl & Kessler 1982) | 6.35 2.23 3.48 2.33 4.38 4.09 2.52 5.19 2.39 3.66 2.29 2.88 | 6.33 2.68 3.52 5.38 2.60 3.53 2.54 4.75 3.98 2.69 3.34 3.17 |
     | `:aarden_essen` (Aarden 2003, OSU dissertation; as in Humdrum `keycor` and music21) | 17.7661 0.145624 14.9265 0.160186 19.8049 11.3587 0.291248 22.062 0.145624 8.15494 0.232998 4.95122 | 18.2648 0.737619 14.0499 16.8599 0.702494 14.4362 0.702494 18.6161 4.56621 1.93186 7.37619 1.75623 |
     | `:temperley` (Temperley 2007, *Music and Probability*, Kostka–Payne corpus) | .748 .060 .488 .082 .670 .460 .096 .715 .104 .366 .057 .400 | .712 .084 .474 .618 .049 .460 .105 .747 .404 .067 .133 .330 |

   - **Check every value against its printed source before pinning it**, especially the Temperley 2007 table, which the best-practices engineer quoted from memory.
     - Use the 2007 Temperley values, not the 1999/CBMS ones (5 2 3.5 2 4.5 4 2 4.5 2 3.5 1.5 4 / 5 2 3.5 4.5 2 4 2 4.5 3.5 2 1.5 4). The 1999 profile was built for present-or-absent input. On duration-weighted Pearson it agreed with only 76.5% of the major/minor chorales, against 88.7% for the 2007 profile.
     - If the 2007 table cannot be verified, ship the 1999 values with that caveat.
   - **The default is `:aarden_essen`.** Agreement with the chorale designation on the 319 major/minor chorales: Aarden 92.5%, Krumhansl–Kessler 80.6% (most of its misses name the dominant). Under Krumhansl–Kessler the story's own example is an exact tie: G minor and C minor both score 0.671231. Aarden answers C minor, 0.913 against 0.605. This is a story change (see below).
   - Histograms are summed in Rational and converted to Float only for the correlation. A zero-variance profile scores 0, never NaN.
   - Specs:
     - the values pinned;
     - an unknown name raises `ArgumentError`;
     - a profile correlates 1.0 with itself;
     - a flat histogram scores 0.
   - Files: `lib/head_music/analysis/key_profile.rb`, `spec/head_music/analysis/key_profile_spec.rb`

3. **`KeyFinder#key` and `#candidates`** (worktree A)
   - `KeyFinder.new(input, profile: :aarden_essen, change_penalty: 1.0, window: 0, **note_input_options)`.
   - `#key` correlates the whole input: the best Key, or nil when there are no notes.
   - `#candidates` answers 24 `Candidate = Data.define(:key, :correlation)` entries, best first, or `[]` when empty.
   - The 24 keys come from a fixed name table, `KEYS`, built with `Key.get`:
     - Majors: C D♭ D E♭ E F G♭ G A♭ A B♭ B.
     - Minors: C C♯ D E♭ E F F♯ G G♯ A B♭ B.
     - The rule is the fewest accidentals. At six, the table takes G♭ major and E♭ minor: one signature for the relative pair, and E♭ minor is the common spelling. (The developer proposed F♯ / D♯ minor; I overrode it.)
   - Ties are sorted by `[-correlation, signature accidentals, major before minor, tonic pitch class]`.
   - Specs:
     - the story example gives C minor;
     - under `profile: :krumhansl_kessler` the same example ties, and the tie-break is pinned;
     - 24 ranked candidates;
     - empty and unpitched-only input give nil and `[]`;
     - identical input gives identical output.
   - Files: `lib/head_music/analysis/key_finder.rb`, `spec/head_music/analysis/key_finder_spec.rb`

4. **`KeyFinder#regions`** (worktree A)
   - **Bar histograms:** each note's duration is split by its overlap with the bars, rather than credited to the bar it starts in.
   - **Local score:** each bar's 24 correlations, summed with ±`window` neighbouring bars through prefix sums. The default is window 0, each bar alone, because summing over bars in the dynamic program already smooths. Measured with Aarden at penalty 1.0, first-region agreement was 92.6% at window 0 against 90.2% at window 1. An empty bar scores 0 for every key, so the key in force carries through it.
   - **Penalty:** Viterbi over bars × 24 keys maximizes Σ local score − `change_penalty` × the number of changes, in units of Pearson correlation. A tie keeps the current key.
   - The default penalty is **1.0, chosen to be conservative.** Regions become key signatures, and written scores seldom change signature for cadential modulations. Measured:

     | Penalty | Chorale changes per piece | Chorale spelling | Invention 1 |
     |---|---|---|---|
     | 1.0 | 0.06 | 99.94% | one C major region, as written |
     | 0.4 | 0.89 | 99.89% | 1:C 4:G 9:Dm 12:Am 15:C |

     Low penalties find more modulations, but spelling barely changes.
   - A one-bar region in the middle of the piece pays the penalty twice, so no minimum region length is needed.
   - A smaller penalty for closely related keys is deferred. The reason: there is no ground truth for regions inside a chorale, and spelling is insensitive to the penalty, so the gain could not be measured.
   - Complexity is bars × 24 × 24. For 500 bars that is about 0.06 s.
   - Specs:
     - cadential tonic-triad material (not scales) in C, G and C, four bars each. Plain scales never switch at any penalty, because a C scale bar correlates A minor 0.824 against C 0.818. Pin regions at bars 1, 5 and 9 under an explicit `change_penalty:` that the spec measures;
     - one chromatic bar does not switch the key at the default;
     - Invention 1 is one C major region at the default, and C G Dm Am C at `change_penalty: 0.4`;
     - a pickup's region begins at bar 0;
     - empty bars carry the key.
   - Same files as step 3.

5. **`LineOfFifths`** (worktree B, on step 1)
   - The index is the letter's index (F −1, C 0, G 1, D 2, A 3, E 4, B 5) plus 7 × the alteration in semitones.
   - A frozen table maps index −15..19 to `Spelling`, built once. `Alteration.by` searches every alteration on each call, so it stays out of the hot loop.
   - `pitch_for(number, index)` builds the pitch with `Pitch.fetch_or_create(spelling, register)`, where `register = (number − spelling.semitones_above_c) / 12 − 1` (`spelling.rb:68-73`, unwrapped), and falls back to `Pitch.from_number`:
     - for more than two accidentals;
     - for a register outside −1..9;
     - whenever the round trip does not match.
   - Two hazards were verified:
     - `Pitch.from_number_and_letter(63, "C")` silently answers C4, because `Alteration.by(:semitones, 3)` is nil (`spelling.rb:56-58`);
     - `Pitch.from_number_and_letter(0, "B")` raises `NoMethodError` (`pitch.rb:72-79`).
   - This follows the guard in `notation/pitch_spelling.rb:12-17`. The rudiments themselves are left alone.
   - Specs:
     - F𝄪4 at 67, C♭4 at 59, B♯3 at 60 (all verified);
     - E𝄫;
     - a triple sharp is refused;
     - key number 0 as B♯ falls back.
   - Files: `lib/head_music/analysis/line_of_fifths.rb`, `spec/head_music/analysis/line_of_fifths_spec.rb`

6. **`PitchSpeller` with a key or regions given: collection and center** (worktree B)
   - `PitchSpeller.new(input, key:)`. `key:` takes a Key, a Mode, something `Key.get` reads, or `Array<KeyRegion>`.
   - `#pitches` answers in input order. `#spelled_notes` answers `SpelledNote = Data.define(:note, :pitch, :rule)`.
   - The inner loop works on integers and builds a Pitch only for the winning spelling.
   - With `t` the tonic's index and `s` the signature's fifths:
     - **Collection:** `s−1 .. s+5`.
     - **Center:** major `t+2` (= s+2); minor `t` (= s+3), so the raised 6th and 7th pull it sharpward; a Mode uses its own collection's center, `s+2`.
     - **Candidates:** the indices congruent to the pitch class, `pc = 7·index mod 12`.
   - Rule 1: a candidate in the collection, or a minor or minor-like mode's raised 6th or 7th (`t+3`, `t+5`), wins outright.
     - `rule:` is `:diatonic` or `:raised`.
     - In the probe this rule never missed: 0 errors in 77,110 notes.
   - Modes keep their own collection rather than taking `Mode#parallel`. On the modal chorales that measured 99.88%, against 99.79% for the parallel key.
     - The PM's G Dorian tie does not exist. A signature of one flat runs B♭..E, centered on G, so F♯ (+6) beats G♭ (−6).
     - E Phrygian G♯/A♭ is a real exact tie. The sonority rule settles it when E and B sound.
   - A KeySignature that is neither a Key nor a Mode (`timeline.rb:208-218`) centers on `s+2`, with no raised degrees.
   - Specs:
     - E♭ major 63/68 → E♭/A♭;
     - A minor 68 → G♯;
     - G♯ minor 67 → F𝄪;
     - G♭ major 59 → C♭4;
     - G Dorian 66 → F♯;
     - for every key from −6 to +6 fifths, each pitch class spelled alone has at most one accidental, except a minor key's raised 7th;
     - regions switch the key at their bar.
   - Files: `lib/head_music/analysis/pitch_speller.rb`, `spec/head_music/analysis/pitch_speller_spec.rb`

7. **`PitchSpeller` tie-breaks: direction, sonority, center** (worktree B)
   - The rules apply only when no collection spelling exists and the two nearest candidates' distances from the center differ by **at most 2**. In C major that makes C♯/D♭, E♭/D♯ and G♯/A♭ follow context, while F♯ and B♭ (a gap of 4) are fixed.
   - **Direction** (`:direction`):
     - when the next note in the same voice is exactly one semitone away, rising takes the sharper candidate and falling the flatter;
     - only a semitone counts. Counting whole steps, and letting the rule touch a minor key's leading tone, lowered the probe to 99.79%;
     - notes given without voices are one voice when none of them overlaps another; otherwise a note with no voice has no successor and the rule does not apply.
   - **Sonority** (`:sonority`):
     - over the notes that start together and are still undecided, enumerate their near-tie candidates jointly, holding already-sounding notes fixed;
     - minimize the span on the line of fifths (max − min), then the summed distance from the center;
     - cap at 4,096 combinations and fall back per note above that (a chorale reaches 16).
   - **Center** (`:center`): the nearer candidate, and the sharper one on an exact tie.
   - Precedence is collection, direction, sonority, center. Measured with the key given:

     | Order | Misses (of 83,196) |
     |---|---|
     | direction before sonority | 47 |
     | sonority before direction | 65 |
     | center alone | 84 |

     Both the PM and the best-practices engineer proposed sonority first; the measurement overrides them.
   - **No running center of gravity.** The best-practices engineer measured one (β = 1, notes from the previous whole note) at +10 notes of 83,196, which is not worth a tuning parameter. Direction and sonority cover "the spellings around it". It is a follow-up if a non-chorale corpus misses.
   - Specs:
     - C major 60–61–62 → C♯ and 62–61–60 → D♭;
     - G–F♯–F keeps F♯;
     - F minor 61–65–68 → D♭–F–A♭;
     - C major 61–65–68 alone → D♭–F–A♭. The story's F minor example never reaches the sonority rule, because the key alone decides it;
     - A–C♯–E–G;
     - every `rule` value appears at least once.
   - Same files as step 6.

8. **Inference and respelling a flow** (needs A and B merged)
   - `PitchSpeller.new(input)` with no `key:`, or with `key: :infer`, uses `KeyFinder#regions`.
   - The first region's tonic follows the table in step 3. Each later region's tonic is the enharmonic spelling nearer the previous region's on the line of fifths, since G♭ against F♯ moves the center 12 fifths.
   - `PitchSpeller.respell(flow, key: nil, **finder_options)` returns a new flow:
     - `key: nil` spells each bar by `timeline.tonal_context_at(bar)` (`timeline.rb:64-66`) and leaves the timeline unchanged. Explicit `:infer` is needed because every timeline opens with a key event that defaults to C major (`timeline.rb:31-41`), so "the flow has none" can never be true.
     - Respelling goes through `hash = flow.to_h` (`flow.rb:209`) and replaces only the String sounds at the addresses the adapter recorded. Pitched sounds are pitch strings (`flow/voice_event_values.rb:8-11`), and unpitched sounds are hashes. Grace-note sounds are replaced too.
     - Under `:infer`, the first region sets `hash["timeline"]["key_signature"]`. Each later region whose fifths differ adds `{"number", "signature" => Timeline.fifths_of(...), "tonal_context" => key.name}`. A relative-key region writes no change, because `RenderPlan#build_measure_key_changes` (`notation/render_plan.rb:93-97`) prints every change.
     - Then `Flow.from_h(hash)`. `project` is not serialized, so the copy has none; a spec states this.
   - Specs:
     - key numbers, positions and rhythmic values are equal, and so is the rest of `to_h` apart from sounds and key signatures;
     - `original.to_h` is the same before and after;
     - a keyed flow keeps its signatures;
     - `:infer` replaces them;
     - a G♯ minor flow writes F𝄪;
     - grace notes are respelled;
     - unpitched parts are untouched.
   - Files: `lib/head_music/analysis/pitch_speller.rb`, `spec/head_music/analysis/pitch_speller/respell_spec.rb`

9. **Fixture evaluation**
   - `SpellingEvaluation.differences(flow, key:)` respells the flow and answers `{count:, grace_count:, differences: ["<position> <role> A♯4 → B♭4", ...]}`.
   - Pin it exactly, once with the key given and once under `:infer`, for:
     - `ABCFixtures::SPEED_THE_PLOUGH` and `CHROMATIC_AIR` (strings in `spec/support/abc_fixtures.rb`; the PM missed them);
     - `spec/fixtures/notation/lily_pond/bach_invention_01.ly`;
     - the six files in `spec/fixtures/notation/kern/`.
   - The developer's prototype found 0 differences with the key given. Counts: 52, 22, 458, then 24/9/16/18/48/49 for the kern files, before grace notes.
   - Files: `spec/support/spelling_evaluation.rb`, `spec/head_music/analysis/fixture_spelling_spec.rb`

10. **Corpus evaluation and the recorded figures**
    - Move the `unreadable` hash out of `spec/head_music/notation/kern_corpus_spec.rb:12-17` into `spec/support/kern_corpus.rb`, shared by both corpus specs.
    - Skip unless `KERN_CORPUS` is set. Parse each chorale once (about 40 s for all 366) and compute everything from that parse, in one aggregate example with `aggregate_failures`:
      - (a) spelling accuracy with the key given;
      - (b) spelling accuracy under `:infer`;
      - (c) `#key` agreement with the designation.
    - For (c), a Mode designation agrees when the inferred key equals `Mode#parallel` (`mode.rb:43`). Report the 319 major/minor chorales and the 47 modal ones (36 Dorian, 9 Mixolydian, 2 Phrygian) separately. Also report first-region agreement, and every miss broken down by `rule`.
    - Each chorale has exactly one designation, so there is no ground truth for regions within a piece.
    - Never print the figures. Record the measured figures in the story's Notes and pin them as floors.
    - Figures to beat, from my probe:

      | Measure | Probe |
      |---|---|
      | (a) key given | 99.94% |
      | (b) inferred | about 99.94% |
      | (c) whole-piece agreement (Aarden) | 90.7% of all 366 |
      | (c) first region (Aarden) | 92.6% |

    - Files: `spec/support/kern_corpus.rb`, `spec/head_music/notation/kern_corpus_spec.rb`, `spec/head_music/analysis/spelling_corpus_spec.rb`, `user-stories/current/key-and-spelling-inference.md`, `CHANGELOG.md`

**Parallel worktrees.**

| Worktree | Steps | Base commit | Notes |
|---|---|---|---|
| C | 0 | dab4eb0b | Independent |
| A | 2 → 3 → 4 | step 1's commit | |
| B | 5 → 6 → 7 | step 1's commit | Needs only `Key.get`, `#key_signature`, `#qualifier`, `#tonic_spelling` and `KeyRegion` |

- Step 1 lands first, on dab4eb0b.
- Name the base commit explicitly when starting each worktree, because isolated agents branch from main.
- The shared contract is the `UnspelledNote`, `KeyRegion` and `NoteInput.for` signatures and option names, plus the 24-key name table, which goes in step 1 as `HeadMusic::Analysis::KeyFinder::KEYS` so B can use it in step 8.
- CHANGELOG lines go in the commit bodies. The coordinator writes them in when integrating, to avoid conflicts.
- Steps 8 to 10 run in order after A and B merge.

### Testing Strategy

- Each criterion is pinned by a small tuple input in `spec/head_music/analysis/`, using `described_class`, with no console assertions.
- Determinism specs run the same input twice and compare `#candidates`, `#regions` and `#spelled_notes`.
- The fixture specs pin exact differences.
- The corpus spec pins floors from measured figures. It is opt-in through `KERN_CORPUS`, like the existing sweep.
- Performance is not asserted. The budget is under 1 s for 10,000 notes over 500 bars, and under 10 s for the corpus's inference on top of parsing.
- Coverage: the fallback branches need explicit specs, namely `LineOfFifths` past a double accidental and at the register edges, the zero-variance histogram, and the 4,096-combination cap.

### Risks & Open Questions

- **Region boundaries are the weakest part.** With Aarden at window 0 and penalty 0.5, Invention 1 opened in G at bar 1, because skipping a change at the start saves a penalty. Nothing in the corpus can check regions within a piece. The default of 1.0 avoids this by rarely changing key; `change_penalty:` is the lever, and the invention spec pins both settings.
- **The figures depend on bar attribution.** My probe credited each note to the bar it starts in. Step 4 splits durations across bars, so the recorded figures may move slightly.
- **Profile values must be checked against the printed sources** before pinning, Temperley 2007 most of all.
- **Probe numbers differ between specialists** (the developer's 99.855%, the best-practices engineer's 99.93%, my 99.94%), because each used a different rule set. They agree that the 98% target is far from binding.
- **Corrections to specialist claims.** The PM's G Dorian tie claim was wrong (see step 6). The developer's tie-break by the lowest note of the first onset is dropped as unnecessary under Aarden, in favor of the fixed sort.
- **The center of gravity is deferred on chorale evidence alone.** Music with long chromatic runs, which MIDI may bring, could want it; the miss-by-rule report will show it.
