<!--
metadata:
  created_at:   2026-11-24T13:44:31-05:00
  activated_at: 2026-11-24T14:36:11-08:00
  planned_at:   2026-11-24T14:40:05-08:00
  finished_at:  2026-11-24T15:14:33-08:00
  updated_at:   2026-11-24T15:14:33-08:00
-->

# Story: Recognize the Escape Tone (Échappée)

## Summary

AS a consumer of the gem grading counterpoint (BardTheory's exercises)
I WANT the gem to recognize an escape tone as a dissonance figure
SO THAT a guide that allows the figure can accept it, instead of marking a well-formed échappée as an untreated dissonance

## Acceptance Criteria

- `HeadMusic::Style::Guideline::DissonanceFigures` answers `escape_tone?(note)`: the note is approached by step from a consonant note and left by a leap of a third in the opposite direction to a consonant note
- The predicate reads shape and the consonance of the notes either side, as the other figures do. Whether the note itself is dissonant, and whether it is unaccented, is the calling guideline's question: `DissonanceFigures` has no meter, and the existing callers ask only about dissonant weak-beat notes
- `DissonanceFigureDetection` delegates `escape_tone?` alongside the existing figures, so any dissonance guideline can opt in through `recognized_figure?`
- Recognition is separate from permission: adding the predicate changes no existing guide's marks. No species guide allows the figure, triple meter included (see Decisions); the eighteenth-century guide is its first user
- The double neighbor takes precedence: the first neighbor of a completed double neighbor (D in C–D–B–C) is not an escape tone, even where B is consonant. The figure predicates stay mutually exclusive
- Specs cover an escape tone above and below its starting note, a step followed by a third in the same direction, a leap wider than a third, a leap to a dissonance, a dissonant starting note, and the double neighbor case
- CHANGELOG entry under Unreleased

## Notes

Raised on 2026-11-24 while reviewing BardTheory's dictionary entry for the double neighbor. The two figures share a step followed by a leap of a third the other way; they differ in where the leap lands. A double neighbor leaps to the second neighbor and steps back to the pitch it started from. An escape tone leaps to a stable tone and moves on.

Today the gem recognizes four figures in `lib/head_music/style/guideline/dissonance_figures.rb`: passing tone, neighbor tone, nota cambiata, and double neighbor. `TripleMeterDissonanceTreatment` accepts a passing tone or a neighbor tone on beats 2 and 3 and nothing else, so an escape tone in a triple-meter exercise is marked as an error.

The escape tone is a three-note figure, so it fills a 3:1 bar exactly, as the neighbor tone does: E–F–D over one cantus firmus note, with F dissonant on beat 2 and D consonant on beat 3.

BardTheory's dictionary entry for the escape tone currently says "Fux doesn't discuss it, and it's rare in Palestrina, but later tonal counterpoint allows it on weak beats." That entry and the `triple-meter-guidelines` lesson stand as they are under the decision below.

### Decisions

- **Triple-meter counterpoint (3:1 third species) does not allow the escape tone** (Rob, 2026-11-24). The figure is introduced in [eighteenth-century-two-voice-counterpoint-guide](eighteenth-century-two-voice-counterpoint-guide.md), which already lists the escape tone among the unaccented figures needing new detection. This story supplies the predicate that guide uses. `TripleMeterDissonanceTreatment` stays as it is. The reasons:
  - The escape tone never resolves. The cambiata and the double neighbor also leap from a dissonance, but the line steps back and the dissonance is accounted for; the escape tone leaves and moves on. Allowing it is a different principle, not an extension of the cambiata's.
  - Sequencing. The triple-meter unit adds the neighbor tone and the beat hierarchy, and third species then presents the cambiata as the first leap from a dissonance. An escape tone one unit earlier would undercut "dissonances leave by step" before it has settled.
  - Grading. A step followed by a third the other way is a common shape in careless writing. With the figure allowed, a triple-meter exercise could no longer say plainly that a dissonance was left by leap.
  - Inside a 3:1 bar the figure is nearly empty anyway: the notes either side of the escape are a step apart and must both be consonant with one cantus firmus note, which leaves only 6–7–5 and 5–4–6.

- **Triple-meter counterpoint does not allow the double neighbor either** (Rob, 2026-11-24). It was raised as the leaping figure that fits a 3:1 bar exactly (C–D–B, then C on the next downbeat) and resolves by step, and a story was drafted and deleted the same day. The reasons:
  - The line does not move. A double neighbor ends on the pitch it started from, and in triple meter it can only start on a downbeat, so it puts the same pitch on two consecutive downbeats. That breaks the spirit of "always move."
  - The other placements are not double neighbors under strict rules. Starting on beat 2 puts the second neighbor on the next downbeat, where it must be consonant, and leaves the first to be quit by leap, which is the escape tone refused above. Starting on beat 3 puts the first neighbor on a downbeat and leaves the second as a dissonance approached by leap.
  - In 4:1 the problem does not arise: the figure starts on beat 1, returns to its pitch on beat 4, and the next downbeat moves on. Third species keeps the figure.
  - The gem's `AlwaysMove` guideline would not have caught the static bar. It marks two adjacent notes at the same pitch, and no guideline reads the pitches of consecutive downbeats.

- **The leap is a third** (Rob, 2026-11-24). The escape tone decorates a step: in D–E–C the starting note and the landing note are a step apart, which makes the leap a third. A wider leap is a looser figure, an incomplete neighbor. The cambiata and the double neighbor test the same third, and the narrow shape excuses the least careless writing.

- **The double neighbor takes precedence over the escape tone** (Rob, 2026-11-24). The four existing predicates are mutually exclusive. Guides OR them together, so an overlap would not change a mark, but it would matter as soon as anything names the figure a note belongs to.

- **Accent is the caller's question** (Rob, 2026-11-24). `DissonanceFigures` is given notes, melodic intervals and a dissonance test, and no meter. The eighteenth-century guide decides where the figure may fall. "Weak relative to the note it leaps to" is not the test: in E–F–D on beats 1–2–3 the landing note is no stronger than the escape tone. The test that guide needs is that the escape tone is not on a strong beat.

- **The predicate ships before its first caller** (Rob, 2026-11-24). Only its own specs exercise it until the eighteenth-century guide lands. That takes one unknown out of the larger story.

## Implementation Plan

Add one predicate to `DissonanceFigures`, following `cambiata_dissonance?`: a private shape test on the melodic intervals, then a consonance test on the notes either side. Delegate it from the mixin. No guideline changes.

### Steps

1. `lib/head_music/style/guideline/dissonance_figures.rb`
   - Public `escape_tone?(note)`: with `start = figure_start(note, 1)`, true when `escape_shape?(start)`, the notes at `start` and `start + 2` are consonant, and `double_neighbor_figure?(start)` is false.
   - Private `escape_shape?(start)`: `figure_intervals(start, 2)` gives the approach and the leap; the approach is a step, the leap's number is 3, and their directions differ. An empty result (the note is first or last in the line) is false.
   - Add the escape tone to the class comment's list of figures.
2. `lib/head_music/style/guidelines/dissonance_figure_detection.rb`: add `:escape_tone?` to the `delegate` list.
3. `CHANGELOG.md`: an Added entry under Unreleased naming `DissonanceFigures#escape_tone?`, saying that no guide allows the figure yet.

### Data model changes

None.

### Tests

`spec/head_music/style/guideline/dissonance_figures_spec.rb`, in the existing ABC harness, all over a held C in the lower voice:

| Upper voice | Intervals with C | `escape_tone?` of the second note |
| --- | --- | --- |
| `a b g e` | 6 7 5 | true: step up, third down |
| `g f a c'` | 5 4 6 | true: step down, third up |
| `e f a g` | 3 4 6 | false: the third continues in the same direction |
| `e g e c` | 3 5 3 | false: the approach is a third |
| `c' d' a g` | 8 9 6 | false: the leap is a fourth |
| `c' d' b a` | 8 9 7 | false: the landing note is dissonant |
| `d' e' c' g` | 9 10 8 | false: the starting note is dissonant |
| `a b g a` | 6 7 5 6 | false, and `double_neighbor_member?` is true |

Also the first and last notes of a line answer false.

`spec/head_music/style/guidelines/dissonance_figure_detection_spec.rb`: `escape_tone?` reaches the figures through the mixin, recognized in a series holding the shape and false for a note outside the series.

The existing guideline specs stand unchanged, which shows that no guide's marks moved.

### Risks

- `a b g a` is the only double neighbor shape whose second neighbor is consonant against a held note a sixth below, so the precedence spec depends on that one line. If the existing double neighbor spec (`g a f g`) were reused, the dissonant F would make the escape tone false on its own and the precedence clause would go untested.
- A consonant note in the escape shape answers true, as a consonant note between two steps answers true to `passing_tone?`. A caller that names figures must ask about dissonant notes only.

## Review

Reviewed 2026-11-24 at `49114e6e`. The two changed spec files pass (24 examples), `spec/head_music/style` passes (2286 examples), and rubocop is clean on the changed files.

### Acceptance criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | `escape_tone?(note)` with the stated shape | ✅ | `lib/head_music/style/guideline/dissonance_figures.rb:42-47`, `:90-95` |
| 2 | Reads shape and the consonance either side; no test of the note itself, no meter | ✅ | `dissonance_figures.rb:42-47` |
| 3 | `DissonanceFigureDetection` delegates `escape_tone?` | ✅ | `lib/head_music/style/guidelines/dissonance_figure_detection.rb:10`; `spec/head_music/style/guidelines/dissonance_figure_detection_spec.rb:67-77` |
| 4 | No existing guide's marks change | ✅ | `escape_tone?` has no caller in `lib` beyond its definition and the delegate; no guideline source or spec is in the diff |
| 5 | The double neighbor takes precedence; predicates stay mutually exclusive | ✅ | `dissonance_figures.rb:46`; `spec/head_music/style/guideline/dissonance_figures_spec.rb:152-159` |
| 6 | Specs cover the seven listed cases | ✅ | `spec/head_music/style/guideline/dissonance_figures_spec.rb:104-167`; at review the same-direction case did not exercise its clause, corrected in `ee09c08d` |
| 7 | CHANGELOG entry under Unreleased | ✅ | `CHANGELOG.md:10-12` |

### Findings

1. **The direction clause is untested.** In `a b d' c'` over C the landing D is a ninth, so the consonance test rejects the line by itself. With `approach.direction != leap.direction` replaced by `true`, every example still passes. The plan's table carries the same flaw ("6 7 9"). `e f a g` over C (3 4 6) is false only because of the direction clause. Fixed in `ee09c08d`: the example now uses that line.
2. **The step approach is untested.** Dropping `step?` from `escape_shape?` keeps every example green. `e g e c` over C (a third up, a third down, all consonant) is false only because of that clause. This case is not on the criteria list. Fixed in `ee09c08d`, which adds that line.
3. **A rest inside the figure does not break it.** `a b z g` and `a z b g` both answer true for B. `passing_tone?` and `neighbor_tone?` read through rests the same way, and only `consonant_run?` breaks at one, so this is consistent with the siblings rather than a regression. The eighteenth-century guide inherits it.
4. **Precedence needs a completed double neighbor, as the criterion says, and the incomplete cases are not pinned.** `a b g` at the end of a line answers true for B, and so does `a b g a` where the closing A is dissonant.

No issues found in edge positions (first, last, second-to-last, a note outside the series), compound or repeated-note intervals, mutual exclusivity with the other four predicates, or the CLAUDE.md conventions.

## Learnings

### What went well

- Shipping the predicate ahead of its first caller kept the story small: one public method, one private shape test, one delegate, and no guide's marks to re-verify.
- Settling the decisions before planning (the third, the double neighbor's precedence, accent as the caller's question) left nothing to argue about during implementation. The plan's risk note on `a b g a` meant the precedence clause was tested by a line that depends on it.
- Following `cambiata_dissonance?` gave the shape test, the consonance test and the edge handling for free.

### What was surprising

- A spec can name a clause without testing it. The same-direction example landed on a ninth, so the consonance test rejected it and the direction clause could be deleted with every example green. The flaw was in the plan's table, where "6 7 9" showed it in plain sight.
- The step approach had no example at all, because the criteria listed the ways an escape tone goes wrong after the step and took the step for granted.
- The figure predicates read through rests. Only `consonant_run?` breaks at one.

### What to do differently

- When a plan lists negative examples, check that each fails for exactly one reason: every other clause of the predicate should hold for that line. For figures over a held note, write the harmonic intervals beside the line and confirm that only the intended note or interval is at fault.
- Have the review delete each clause in turn and re-run the specs. It found both gaps in minutes.
- Decide whether a rest breaks a figure before the eighteenth-century guide calls these predicates, and settle it for all five at once.
