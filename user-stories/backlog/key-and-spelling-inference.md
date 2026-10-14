<!--
metadata:
  created_at:   2026-10-14T15:16:39-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-10-14T15:16:39-07:00
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
- [ ] The key profiles are named and selectable (Krumhansl–Kessler by default, plus at least one alternative such as Temperley's), and each is documented with its source
- [ ] Over a whole piece, the key finder answers key regions, each beginning at a bar's downbeat, since the timeline changes keys only there. A documented penalty for changing key keeps it from switching key every bar
- [ ] Input with no notes answers no key, rather than raising

### Spelling

- [ ] Given a key, the speller spells every key number. When the key is not given, it uses the key finder's regions
- [ ] Every key number in the key's diatonic collection is spelled diatonically. In E♭ major, 63 is E♭ and 68 is A♭
- [ ] The raised leading tone of a minor key is spelled as raised: in A minor, 68 is G♯, and in G♯ minor, 67 is F𝄪
- [ ] Chromatic notes follow melodic direction where the line of fifths is near a tie. In C major, 60–61–62 spells C♯, and 62–61–60 spells D♭
- [ ] Notes sounding together are spelled to keep the sonority in thirds where one spelling does. In F minor, 61–65–68 is D♭–F–A♭, not C♯–F–G♯
- [ ] Double sharps and double flats appear only where the line-of-fifths distance from the key calls for them
- [ ] Respelling a flow returns a new flow with the same key numbers and timing, and its key signature changes set from the key regions when the flow has none. The flow passed in is unchanged

### Evaluation

- [ ] The ABC, LilyPond, and kern fixtures, stripped to key numbers, are respelled. Their accuracy against the written spelling is pinned in specs: the note count and every note that differs
- [ ] With `KERN_CORPUS` pointing at the Bach chorales, a spec measures and records spelling accuracy twice: with the key from the file's key signature and designation, and with the key inferred. It also measures how often the inferred key of each chorale agrees with its `*G:`-style designation. The measured figures are recorded in this story and pinned as floors
- [ ] Spelling with the key given reaches at least 98% of notes on the chorales
- [ ] Maintains 90%+ test coverage

## Notes

- **Major and minor only.** Key-finding profiles exist for major and minor. Modal finding (Dorian, Phrygian, …) needs profiles the literature does not settle, and the Renaissance repertoire that would want it arrives mostly spelled, through kern and MEI. A follow-up could infer the final and mode from cadences instead.
- **No atonal spelling.** Atonal and twelve-tone music is spelled by different conventions, such as sharps rising and flats falling regardless of key. The melodic-direction rule above is a start, but a key-free speller is a follow-up.
- `Pitch.get(number)` keeps its sharp spelling. Callers that know their context use the speller.
- Sources to cite in the code: Krumhansl, *Cognitive Foundations of Musical Pitch* (1990); Temperley, *The Cognition of Basic Musical Structures* (2001); Meredith, "The ps13 pitch spelling algorithm," *Journal of New Music Research* 35 (2006).

## Decisions

- **This story is a prerequisite of MIDI Import** (decided 2026-10-14), split out so the inference can serve other callers and be judged on spelled corpora before any MIDI reading exists.
- **It lives in `HeadMusic::Analysis`** (decided 2026-10-14), as the original MIDI Import story suggested.

## Open Questions

1. Should the speller also answer a confidence for each note, so MIDI Import can flag doubtful spellings?

## Implementation Plan

[to be filled in by /stories plan]
