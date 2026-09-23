<!--
metadata:
  created_at:
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-23T09:58:04-07:00
-->

# Sixteenth-Century (Renaissance) Style Guides

AS a counterpoint student or researcher

I WANT a sixteenth-century cantus firmus guide and sixteenth-century counterpoint species guides

SO THAT I can analyze modal, Palestrina-style vocal counterpoint against its own rule system rather than forcing it through the eighteenth-century-derived guides

## Background

The existing guides descend from Fux's eighteenth-century synthesis and its twentieth-century restatements. Sixteenth-century vocal polyphony (Palestrina style) is a **distinct tradition**, not a dialect of that synthesis — which is precisely what makes it worth adding: a Renaissance guide differs *substantially* from the current guides, unlike a modern-author cantus firmus split (see `split-counterpoint-species-by-author.md`), which would differ only marginally.

Concrete melodic differences in the Renaissance style include: the sixth admitted only as an **ascending minor sixth**; a leap larger than a third answered by a step in the opposite direction; the **nota cambiata** figure; melodic range of about a tenth; the high note touched **once**; and careful *musica ficta* / leading-tone (subsemitonium) treatment at cadences. Dissonance handling (suspensions, passing and neighbor tones, the cambiata) and cadence formulas also differ from the later species tradition.

## Current State

- Melodic guides subclass `HeadMusic::Style::Guides::SpeciesMelody`, which carries a tonal `MELODIC_CORE` including `Guidelines::Diatonic` — a **key-signature-based** check.
- Harmonic guides subclass `HeadMusic::Style::Guides::SpeciesHarmony` with a `HARMONIC_CORE`.
- Guidelines are configurable via `Annotation.with(...)`.

The tonal `MELODIC_CORE` is a poor fit for modal music: "in key" in the sixteenth century means modal degrees plus *ficta*, not a major/minor key. Reusing `Diatonic` as-is would misrepresent modal practice.

## Architectural approach

Introduce a **separate modal lineage** rather than subclassing the tonal species bases:

- A `ModalMelody` base with a `MODAL_CORE`, parallel to `SpeciesMelody`/`MELODIC_CORE`.
- A `ModalHarmony` base with a `MODAL_HARMONIC_CORE`, parallel to `SpeciesHarmony`/`HARMONIC_CORE`.
- Genuinely shared, mode-agnostic guidelines (e.g. climax, singable range) may be reused directly; mode-sensitive ones (diatonic/ficta, cadence) get modal variants.

Both bases inherit analysis behavior from `Guides::Base`, exactly as the tonal bases do.

Prefer Schubert's **"hard" (technical) vs. "soft" (stylistic)** rule distinction as the organizing principle — it maps directly onto the existing constraint-vs-guideline model.

## Scope

- `SixteenthCenturyCantusFirmus` (modal cantus firmus).
- Sixteenth-century counterpoint species guides (first through fifth, or the subset the sources treat), as `ModalHarmony` subclasses.
- New modal guidelines where the tonal ones do not apply (modal-degree/ficta check, ascending-minor-sixth-only leaps, nota cambiata, cadence formulas).

## Scenario: A modal cantus firmus guide exists

Given a modal melody in a church mode

When I analyze it under `Guides::SixteenthCenturyCantusFirmus`

Then it is judged against modal rules (modal final, ficta, ~tenth range, single high point, ascending-minor-sixth-only leaps)

And it does not inherit the tonal `Diatonic` key-signature check

## Scenario: Ascending minor sixth is the only permitted sixth

Given a melodic line containing a descending sixth or a major sixth

When it is analyzed under the sixteenth-century guide

Then the leap is flagged

And an ascending minor sixth in the same context is not flagged

## Scenario: Leap recovery in Renaissance style

Given a leap larger than a third

When it is analyzed under the sixteenth-century guide

Then the guide expects the next motion to be a step in the opposite direction

## Scenario: Nota cambiata is recognized

Given the nota cambiata figure in a counterpoint voice

When it is analyzed under a sixteenth-century counterpoint guide

Then the otherwise-dissonant note in the figure is not flagged

## Scenario: Modal cadence with musica ficta

Given a cadential approach requiring a raised leading tone (subsemitonium)

When it is analyzed under the sixteenth-century guide

Then the ficta alteration is treated as idiomatic rather than as an out-of-mode error

## Scenario: Modal lineage is separate from the tonal lineage

Given the new Renaissance guides

When I inspect the class hierarchy

Then they descend from modal bases (`ModalMelody` / `ModalHarmony`), not from `SpeciesMelody` / `SpeciesHarmony`

And tonal-only guidelines (e.g. key-signature `Diatonic`) are absent from the modal cores

## Scenario: Validated against worked Renaissance examples

Given a Palestrina-style example from a source text

When it is analyzed under the sixteenth-century guides

Then the guide reports adherence (or the source's own flagged faults) matching the text

## Open questions

- Which modes to support first, and how the guide receives the mode (from the composition's key signature vs. an explicit mode).
- How much of the tonal `MELODIC_CORE` is genuinely mode-agnostic and can be shared versus re-implemented.
- Whether to model *ficta* as automatic (inferred at cadence) or as pitches supplied in the input.

## Sources

- Knud Jeppesen, *Counterpoint: The Polyphonic Vocal Style of the Sixteenth Century* (1931) — historical anchor.
- Peter Schubert, *Modal Counterpoint, Renaissance Style* (Oxford) — modern academic standard; "hard"/"soft" rule distinction.
- Robert Gauldin, *A Practical Approach to Sixteenth-Century Counterpoint* — clear, widely-adopted rule lists.

## Jeppesen as the primary source

Moved here on 2026-09-23 from
[Fifth Species Guide Improvements](../current/fifth-species-guide-improvements.md),
which had planned to grade Jeppesen's fifth-species examples under the
Fux-derived guides and to cite him for changes to them. Fux represents
eighteenth-century practice; Jeppesen describes Palestrina's, which is this
story's tradition. His book is the natural primary source for the modal
guides, and his examples are their validation set.

- Jeppesen, Knud. *Counterpoint: The Polyphonic Vocal Style of the
  Sixteenth Century*, trans. Glen Haydon. Prentice-Hall, 1939; the 1960
  printing is public on the Internet Archive at
  <https://archive.org/details/counterpointpoly00jepp>, with OCR text and a
  PDF whose page number is the printed page plus 22.
- Passages: the modes and their accidentals, pp. 60 to 62 and 73 (C-sharp in
  dorian, F-sharp in mixolydian, G-sharp in aeolian raise the third of the
  dominant triad at cadences; "B-flat was often used in all modes instead of
  B" in descending figures and to avoid F against B, but not "if the
  progressions continued upward to the C"; in polyphony the lydian "B is
  changed to B-flat"); the anticipation, pp. 94 to 95 and 148 to 149, and
  the summary p. 290 ("an unaccented quarter note which anticipates the
  following accented note", "used only when approached by step from above",
  "generally occurs before a syncopated note" but "does appear quite often
  without being followed by a suspension"); tonal repetition, p. 94 ("very
  common ... especially with longer note values", governed by the text); the
  culmination, p. 95 note 9 and pp. 122 to 123 (repeated in quicker rhythms
  "only if it comes on two tones which are separated by a single tone", his
  example separating by a third; a culmination at the very end
  "inadvisable"); the unison, pp. 116 to 117, 160, and the summary p. 288
  (a second-species preference, "so far as possible"; in free counterpoint
  "freely, of course, but with caution"); fifth-species rhythm, pp. 135 to
  139 ("only a poor melody would have the first four measures in half notes,
  the next four in quarter notes"; contrasts "introduced smoothly and
  evenly"; in descending movement longer values before shorter, in ascending
  "quite correct to begin with the quicker notes"); the fifth-species
  examples, pp. 149 to 152; the summary of rules, pp. 288 to 291.
- Notation differences from Fux that a modal guide must accept: the dotted
  half where Fux ties a half to a quarter ("the anticipation usually follows
  a dotted half", p. 94); a whole note or dotted half opening the line;
  quarters dissonant after a suspension or dotted half; the cambiata opening
  on a dotted half; an anticipation that dissonates. Ars Nova's
  fifth-species instructions say "Dotted notes will not be used", which is
  the eighteenth-century position.
- Examples, pp. 149 to 151, one per mode, each a three-stave system with the
  counterpoint above in soprano clef, the cantus firmus in alto clef, and
  the counterpoint below in tenor clef, in cut time. Only the dorian sits on
  Fux's cantus; the other four use Jeppesen's own: phrygian
  `E4|D4|E4|F4|G4|A4|D4|F4|E4`, mixolydian `G,4|D4|C4|A,4|B,4|C4|B,4|A,4|G,4`,
  aeolian `A,4|A4|G4|E4|F4|E4|D4|C4|B,4|A,4`, ionian
  `C4|E4|F4|G4|E4|A4|G4|E4|F4|E4|D4|C4`. A triple-meter ionian example is on
  p. 152. He marks cambiatas with a small `c` and anticipations with an
  asterisk.
- A first transcription of the ten duple-meter lines, one agent's reading
  from a 300 dpi render, unverified note by note and to be re-read before
  any pinning (ABC, `L:1/4`, `M:4/4`, cantus as above):
  dorian above `A4-|A2 F2|G2 A2|_B3 A|_B c d e|f e d2-|d2 c d|e f g e|a2 d2-|d ^c/2 B/2 ^c2|d4|]`,
  below `z2 D,2-|D,2 D2-|D2 C2|_B,2 D2|C2 _B,2|A,3 G,|F, G, A, B,|C D E2-|E D D2-|D ^C/2 B,/2 ^C2|D4|]`;
  phrygian above `B2 G2|A2 B2|c3 B|A B c d|e f g2-|g2 f2-|f e d2-|d c A2|B4|]`,
  below `z2 E, F,|G, A, B, G,|C3 B,|A,2 D2|E3 D|C B, A, G,|F, E, D, C,|D,4|E,4|]`;
  mixolydian above `z2 G2-|G2 F2|E2 e2-|e d c B|G A B2-|B2 A2-|A G G2-|G ^F/2 E/2 ^F2|G4|]`,
  below `z2 G,2|F,2 G,2|A,2 B,2|C D E2-|E2 D C|A, B, C A,|D2 G,2-|G, ^F,/2 E,/2 ^F,2|G,4|]`;
  aeolian above `z2 e2-|e2 d c|B2 G2|c3 B|A B c d|e f g2-|g2 f2|e E A2-|A ^G/2 ^F/2 ^G2|A4|]`,
  below `A,3 B,|C B, A, G,|E, F, G,2-|G,2 F, E,|D,2 D2-|D2 C2|B,2 A, G,|A, E, A,2-|A, ^G,/2 ^F,/2 ^G,2|A,4|]`;
  ionian above `c3 B|G A B c|d e f2-|f2 e d|c2 g2-|g2 f2|e3 d|c2 B2|A2 d2-|d c c2-|c B/2 A/2 B2|c4|]`,
  below `z2 C2-|C2 A,2-|A,2 F2|E3 D|C B, A, G,|F, G, A, B,|C G, C2-|C B, A,2-|A,2 D2-|D2 C2-|C B,/2 A,/2 B,2|C4|]`.
- Graded under the current Fux-derived fifth-species guides as a scratch
  measurement, not pinned: composite 0.873 to 0.985, melody 0.761 to 0.988,
  harmony 0.921 to 1.000; no harmony primary mark on any line; every melody
  primary mark is `AllowFifthSpeciesRhythmicValues` on a dotted half or on
  the body whole notes at dorian above 1:1 and phrygian below 8:1. All ten
  lines are adherent to the prototype mixture guideline. Secondary findings
  worth a modal guide's attention: the raised-seventh eighth that steps down
  before returning (`^c/2 B/2 ^c2` and its cousins) and the raised sixth in
  the aeolian cadence charged by `Diatonic`; `EndOnTonic` on phrygian above,
  which ends on the fifth; voice crossing on the aeolian and mixolydian
  lower lines against his leaping cantus.
