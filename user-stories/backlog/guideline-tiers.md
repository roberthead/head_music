<!--
metadata:
  created_at:   2026-08-08T15:28:17-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-08-08T15:28:17-07:00
-->

# Guideline Tiers

AS an application presenting a guide's rules to a student

I WANT each rule in a ruleset to declare whether it is what the guide is *about* or background craft it inherits

SO THAT a rubric built for grading can also be read as instructions, without the consumer reverse-engineering the distinction from weights

## Background

A guide's ruleset is currently a flat array. That is the right shape for grading — every rule produces an annotation, annotations combine by weight — but it loses a distinction the guides already make when they are built.

`Guides::ContourMelody` is the clearest case. It composes `DiatonicMelody`'s ruleset with a contour rule, and in doing so partitions the rules three ways:

```ruby
GATES, WEIGHTED_PEERS = begin
  gates, peers = DiatonicMelody::RULESET.partition(&:default_gate?)
  peer_weight = PEER_WEIGHT_BUDGET / peers.length
  [gates.freeze, peers.map { |rule| rule.with(weight: peer_weight) }.freeze]
end
```

Gates, deliberately down-weighted peers, and `Contoured` left at its default weight of φ⁻¹. The partition exists, is meaningful, and is thrown away — `.ruleset` returns the three groups concatenated.

A consumer that wants to *show* a ruleset needs the partition back. Twelve rules presented as one undifferentiated list is a correct rubric and unusable instructions: an early student told to write an arch melody should read "write a melody with the arch contour" first and "prepare your octave leaps" as background, not the reverse in alphabetical accident.

## Current state

Ruleset entries carry two per-rule attributes, each following the same pattern — a class-level default, overridable through `Annotation.with(...)`:

| Attribute | Class default | Override | Resolved on instance |
| --- | --- | --- | --- |
| gate | `Annotation.default_gate?` | `gate:` | `Annotation#gate?` |
| weight | `Annotation.default_weight` | `weight:` | `Annotation#weight` |

`Annotation::Configured` mirrors `default_gate?` so that build-time ruleset filters can classify an entry uniformly, whether it is a bare class or a configured wrapper. `default_weight` has no such mirror, because nothing yet reads weight before analysis.

Only the `MinimumThreshold` subclasses (`MinimumNotes`, `MinimumMelodicIntervals`) default to being gates.

## Scope

Add `tier` as a third per-rule attribute in exactly the pattern `gate` and `weight` establish. Three values:

| Tier | Meaning |
| --- | --- |
| `:required` | Must hold, or the analysis scores zero. Every gate. |
| `:primary` | What this guide is about. The default. |
| `:secondary` | Background craft this guide inherits rather than teaches. |

Two rules make the values fall out rather than needing to be declared everywhere:

1. **A gate is `:required` by definition.** `tier` reports `:required` whenever `gate?` is true, without the guide saying so.
2. **`:primary` is the default.** Demotion is the deliberate act. A guide only demotes peers when it has a defining rule to demote them *relative to* — so a guide that never demotes anything (plain `DiatonicMelody`, where the exercise genuinely is "write a good melody") reports all its rules primary, which is correct rather than a degenerate case.

The consequence for `ContourMelody` is one added keyword on the line that already re-weights:

```ruby
peers.map { |rule| rule.with(weight: peer_weight, tier: :secondary) }
```

`Contoured` needs nothing.

## Scenarios

### Scenario: A rule defaults to primary

Given a guideline class that declares no tier

When I read its resolved tier

Then it is `:primary`

### Scenario: A gate reports as required

Given `MinimumNotes.with(8)`, whose class defaults to being a gate

When I read its resolved tier

Then it is `:required`

And the guide never had to declare it

### Scenario: A rule made a gate by configuration reports as required

Given a guideline whose class does not default to being a gate

When it is configured with `gate: true`

Then its resolved tier is `:required`

### Scenario: A guide demotes its inherited peers

Given `Guides::ContourMelody.with(contour: :arch, minimum_melodic_intervals: 2)`

When I read the tier of each entry in its ruleset

Then `Contoured` is `:primary`

And the rules inherited from `DiatonicMelody` are `:secondary`

And `MinimumNotes` is `:required`

### Scenario: A guide with no defining rule keeps every rule primary

Given `Guides::DiatonicMelody`, which demotes nothing

When I read the tier of each non-gate entry in its ruleset

Then every one is `:primary`

### Scenario: Tier is readable before analysis

Given a ruleset entry, whether a bare guideline class or an `Annotation::Configured`

When I read its tier without constructing an annotation

Then it resolves, so a ruleset can be partitioned at build time and presented without a voice

### Scenario: Tier is readable on an annotation

Given an annotation produced by analyzing a voice

When I read its tier

Then it matches the tier of the ruleset entry that produced it, so a serializer can group results without re-deriving the ruleset

### Scenario: Tier does not affect fitness

Given two rulesets identical but for their tiers

When each analyzes the same voice

Then the fitness is the same

And tier appears nowhere in the weighting arithmetic

## Design notes

**Tier belongs to the guide, not to the consumer.** The same guide used in two applications should highlight the same rule. Pushing the distinction out to a per-consumer list — an exercise config, a display map — rebuilds a hand-maintained table that drifts from the ruleset it describes. The gem already retired one such table when guides learned to declare their own `category`.

**Rejected: deriving tier from weight.** The information is technically present — `ContourMelody`'s peers sit at φ⁻²/10 while `Contoured` sits at φ⁻¹ — and a threshold would separate them today. Rejected because it couples two things that should move independently: tuning the grading arithmetic would silently change what a student reads, and the threshold itself is a magic number defensible in no particular place.

**Tier is an open enum, like `category`.** Three values cover what the guides express today. Nothing should switch exhaustively on it.

## Out of scope

Two sibling concerns share a motivation with this story but do not belong in it:

- **Lifting `message` to the class level and into the locale files.** A ruleset's messages are what a consumer would actually render; today `message` is only reachable on an instance, and `Annotation::Configured` has no `message` at all. Separate story.
- **A `criteria` reader on guides.** The natural consumer of both tier and class-level messages — `ruleset` mapped to presentable entries. It should land after both, not alongside either.

Tier is independently useful before those exist: an annotation answering `tier` is enough for a consumer to group analysis results, which is the nearer-term need.

## Open questions

- Should `Annotation::Configured` also mirror `default_weight` while adding `default_tier`? Nothing reads weight at build time today, but the asymmetry becomes visible once one of the three attributes has a mirror and another does not.
- Is `:secondary` the right name, or does something like `:supporting` read better in a rail heading a student sees?
- Do any existing multi-rule guides beyond `ContourMelody` have a defining rule that should demote its peers — the species harmony guides, say — or is `ContourMelody` genuinely the only one today?

## Implementation Plan

[to be filled in by /stories plan]
