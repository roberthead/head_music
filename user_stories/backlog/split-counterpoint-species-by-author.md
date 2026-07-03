# Split Counterpoint Species Guides by Pedagogical Author

AS a counterpoint student or researcher

I WANT the species counterpoint guides attributed to specific 20th-century pedagogues (Salzer & Schachter, Schoenberg, Davis & Lybbert)

SO THAT an analysis can be judged against a named, citable rule-set rather than a vague "modern" composite, and the differences between these traditions become explicit and testable

## Background

The style guides currently offer `FuxCantusFirmus` (named by treatise) alongside a generic `ModernCantusFirmus` and a single set of species guides (`FirstSpeciesMelody`/`FirstSpeciesHarmony` … `FifthSpeciesMelody`/`FifthSpeciesHarmony`). "Modern" is a composite that does not correspond to any one author, which makes its rules hard to defend or cite.

Research into the primary texts (see Sources) established two things that shape this story:

1. **The bare cantus firmus has largely converged** across these authors — stepwise motion, diatonic pitches, a single unrepeated climax, begin/end on the tonic, ~8–16 notes, leaps recovered by step. A four-way split of the *cantus firmus itself* would produce near-duplicate classes differing by one or two knobs. **We deliberately do not split the CF by modern author.**

2. **The real divergences live in the added counterpoint and the higher species** — dissonance treatment on weak beats, cadence formulas and leading-tone handling, tolerance for parallel/direct perfect intervals, the *nota cambiata* and other idiomatic figures, and battuta. That is where author attribution earns its keep, and where this story focuses.

Kennan (*Counterpoint: Based on Eighteenth-Century Practice*) is intentionally **out of scope**: his book is a Bach-style free-counterpoint text organized around the single melodic line, invention, canon, and fugue, not a Fuxian species cantus firmus. His principles belong to a future `MelodicLine` guide, not a species guide.

## Current State

- Melodic species guides subclass `HeadMusic::Style::Guides::SpeciesMelody` and splat `MELODIC_CORE` into their `RULESET`.
- Harmonic species guides subclass `HeadMusic::Style::Guides::SpeciesHarmony` and splat `HARMONIC_CORE`.
- Individual guidelines are now configurable through the `Annotation.with(...)` factory (e.g. `MinimumNotes.with(8)`), so per-author threshold differences can be expressed without new subclasses.
- `references/` already holds pedagogical surveys for second through fifth species that map cross-source comparisons onto this architecture.

## Scope

Attribute the **species counterpoint** guides (the added-voice / harmony guides, and any melody guides whose rules differ) to three authors:

- **Salzer & Schachter** — *Counterpoint in Composition* (1969), Schenkerian.
- **Schoenberg** — *Preliminary Exercises in Counterpoint* (1963), tonal-functional.
- **Davis & Lybbert** — *The Essentials of Counterpoint* (1969).

The single cantus firmus guide remains shared; only the counterpoint diverges by author.

## Known author deltas (to be confirmed against the books)

- **Salzer & Schachter**: permit **all** horizontal sixths (Fux/Jeppesen allow only the ascending minor sixth); one climax, never repeated; range may exceed two octaves at the climax; avoid simultaneous leaps, especially same-direction leaps larger than a fourth.
- **Schoenberg**: reframes species on major/minor functional tonality; the leading-tone (7̂→1̂) cadence is idiomatic rather than exceptional; generally more permissive framing.
- **Davis & Lybbert**: rules could not be sourced online — the specific deltas must be transcribed from the book in hand before implementation.

## Scenario: A named author guide exists per species

Given the species counterpoint guides

When I look up the first-species counterpoint for a given author

Then I find a guide such as `Guides::SalzerSchachterFirstSpeciesHarmony` (or equivalent naming)

And its `RULESET` splats the shared `HARMONIC_CORE` plus that author's species-specific rules

## Scenario: Author guides differ only where the sources differ

Given two author guides for the same species

When I compare their rulesets

Then rules the authors share remain in `HARMONIC_CORE` (not duplicated per author)

And only the sourced, author-specific rules appear inline

## Scenario: Sixths differ between authors

Given a melodic line that uses a descending or major sixth

When it is analyzed under a Salzer & Schachter guide

Then the sixth is permitted

And when the same line is analyzed under a stricter author's guide that allows only the ascending minor sixth

Then the sixth is flagged

## Scenario: Cantus firmus is not split by modern author

Given the modern cantus firmus

When author guides are introduced

Then a single shared cantus firmus guide is retained

And no `SalzerSchachterCantusFirmus` / `SchoenbergCantusFirmus` / `DavisLybbertCantusFirmus` classes are created

## Scenario: Each author guide is validated against worked examples from its source

Given a cantus firmus and counterpoint example printed in an author's text

When it is analyzed under that author's guide

Then the guide reports adherence (or the author's own flagged faults) matching the book

## Open questions

- Naming convention: `AuthorSpeciesHarmony` vs. a namespace per author (`Guides::SalzerSchachter::FirstSpeciesHarmony`)?
- Do any **melodic** species rules diverge by author, or is the divergence confined to the harmonic (added-voice) guides?
- Should `HARMONIC_CORE` be trimmed if a rule turns out to be author-specific rather than universal?

## Sources

- Kent Kennan, *Counterpoint: Based on Eighteenth-Century Practice* (1959) — establishes why Kennan is out of scope for species CF.
- Felix Salzer & Carl Schachter, *Counterpoint in Composition* (1969).
- Arnold Schoenberg, *Preliminary Exercises in Counterpoint* (1963).
- Ferdinand Davis & Donald Lybbert, *The Essentials of Counterpoint* (1969).
