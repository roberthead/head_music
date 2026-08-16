<!--
metadata:
  created_at:   2026-08-16T00:00:00-07:00
  activated_at: 2026-08-16T15:20:29-07:00
  planned_at:
  finished_at:
  updated_at:   2026-08-16T15:20:29-07:00
-->

# Rename Annotation to Guideline

AS a developer reading the style layer

I WANT the base class of the sixty-three guideline classes to be called `Guideline`

SO THAT `Guidelines::ConsonantClimax < Style::Guideline` says what it is, and the word "annotation" stops meaning two things at once

Story 1 of the [Style Assessment Model](../epics/style-assessment-model.md).
Blocks [First-Class Guide Items](../backlog/first-class-rules.md), which assumes this
rename has landed.

## Background

`Style::Annotation` is the base class every guideline subclasses *and* the
result an analysis produces. One class, two roles, one name — so "annotation"
already means both the rule and the finding, and the file tree says so:
`Style::Guidelines::ConsonantClimax` is a guideline whose superclass is an
annotation.

The model this epic is building splits those roles into `Style::Guideline` and
`Style::GuideItemAssessment`. That split is story 2. This story does only the
half that can be verified by running the suite: the class keeps both roles, and
takes the name that matches the role it plays in sixty-three of its
sixty-four appearances.

Doing it separately is the point. Story 2's acceptance test is that every
guide's fitness comes out bit-identical, which is cheap and total — but only
readable as a diff if a rename of this size is not mixed into it.

## Scope

A rename, and one deletion that is part of the same vocabulary cleanup.

### The rename

| From | To |
| --- | --- |
| `HeadMusic::Style::Annotation` | `HeadMusic::Style::Guideline` |
| `HeadMusic::Style::Annotation::Configured` | `HeadMusic::Style::Guideline::Configured` |
| `lib/head_music/style/annotation.rb` | `lib/head_music/style/guideline.rb` |
| `lib/head_music/style/annotation/configured.rb` | `lib/head_music/style/guideline/configured.rb` |
| `spec/head_music/style/annotation_spec.rb` | `spec/head_music/style/guideline_spec.rb` |

Both `require` lines in `lib/head_music.rb` (185–186) move with them. Load order
is unchanged: nothing between `analysis` and `mark` depends on the name.

`Style::Guideline` and the existing `Style::Guidelines` module differ by one
character, which is the pattern `Style::Guide` and `Style::Guides` already
establish and which nothing in the codebase has had trouble with. Every
guideline file declares its class fully qualified
(`class HeadMusic::Style::Guidelines::Contoured < HeadMusic::Style::Annotation`),
so the lexical scope in those bodies is `Object` and no unqualified `Guideline`
can resolve ambiguously.

### Dropping `annotation_messages`

`Analysis#messages` has an `annotation_messages` alias with twelve call sites
across four guide specs. It names a collection that this epic is renaming out
from under it, and it adds nothing over `messages`. Delete the alias; rewrite
the twelve sites to `messages`.

### What does *not* change

- **`Analysis#annotations` keeps its name.** It returns `Guideline` instances for
  the length of this story, which reads oddly and is deliberate — renaming it to
  `guide_item_assessments` is meaningless until story 2 introduces the type it
  would be returning. Keeping it makes this story a rename with no design
  decisions in it.
- **No `Annotation = Guideline` deprecation alias.** The epic commits to a clean
  break, and an alias would keep the name alive exactly when the point is to
  retire it. Both this story and story 2 land in the unreleased 20.0.
- **No behavior of any kind.** `default_gate?`, `default_weight`, `with`,
  `fitness`, `marks`, and every guideline body are untouched.

## Spec-side details worth knowing before starting

Two places reach into the class rather than merely referencing it:

- **`spec/spec_helper.rb:58` reopens it** to add `marks_count`, `first_mark`,
  `first_mark_code`, and `marks_array`. It becomes
  `class HeadMusic::Style::Guideline` here. (Story 2 makes `new` private and
  stops the instance escaping, so these helpers move to `GuideItemAssessment`
  then — not this story's problem, but it is the thing most likely to be
  forgotten.)
- **`ConfiguredGuidelineHelper#configured`** matches on `guideline_class:` and
  `options:`, which are `Configured`'s readers. Both reader names survive this
  story unchanged.

Roughly 48 occurrences of `Annotation` in `lib/` and 12 in `spec/`, plus 128
lowercase `annotation`/`annotations` occurrences in `spec/` — mostly local
variable names and `#annotations` calls. The lowercase ones are free to rename
for readability where they name a guideline instance, and free to leave where
they name the `Analysis#annotations` collection that survives.

## Acceptance Criteria

- `HeadMusic::Style::Guideline` exists, and `HeadMusic::Style::Annotation` does
  not resolve.
- All sixty-three classes in `Style::Guidelines` load, whether they name the base
  class directly (44 of them) or inherit through an intermediate guideline base
  class such as `MinimumThreshold`, `NoParallelPerfect`, `NoteCountPerBar`,
  `DirectionChanges`, `FirstBarEntry`, `DirectionalStepToFinalNote`, or
  `WeakBeatDissonanceTreatment`.
- `HeadMusic::Style::Guideline::Configured` exists with `guideline_class`,
  `options`, `new(voice)`, `with`, `default_gate?`, and `name` unchanged.
- `Style::Guide::ALL.each(&:ruleset)` still resolves at load, so every registered
  guide's ruleset constant is intact.
- `Analysis#annotation_messages` no longer exists; `Analysis#messages` is
  unchanged and the twelve former call sites use it.
- The full suite passes with no changes to any expected value — same fitnesses,
  same messages, same adherence.
- `bundle exec rubocop` is clean.
- No file, constant, comment, or spec description in `lib/` or `spec/` refers to
  the base class as an annotation.

## Scenarios

### Scenario: A guideline names its superclass

Given `Guidelines::ConsonantClimax`

When I read its superclass

Then it is `HeadMusic::Style::Guideline`

### Scenario: An intermediate base class still connects

Given `Guidelines::MinimumNotes`, which subclasses `Guidelines::MinimumThreshold`

When I read its ancestors

Then `HeadMusic::Style::Guideline` is among them, and `MinimumNotes.with(8)` still produces a configured entry that gates

### Scenario: Configured entries are unchanged

Given a ruleset containing `Guidelines::MinimumNotes.with(8)`

When the analyze loop calls `#new(voice)` on it

Then it produces the same result it did before the rename

### Scenario: Every guide grades exactly as it did before

Given each of the seventeen registered guides and a fixed corpus of voices

When each analyzes each voice

Then the fitness, the adherence, and the messages are unchanged

### Scenario: The alias is gone

Given a `Style::Analysis`

When I call `annotation_messages`

Then it raises `NoMethodError`, and `messages` returns what it always did

## Notes

This is a mechanical story with one judgment call in it — whether to keep a
deprecation alias — answered above. If the diff turns out to contain anything
that is not a rename, that thing belongs in story 2.

## Implementation Plan

[to be filled in by /stories plan]
