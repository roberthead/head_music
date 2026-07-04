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
