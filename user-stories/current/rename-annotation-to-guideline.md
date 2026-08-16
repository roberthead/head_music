<!--
metadata:
  created_at:   2026-08-16T00:00:00-07:00
  activated_at: 2026-08-16T15:20:29-07:00
  planned_at:   2026-08-16T15:42:44-07:00
  finished_at:
  updated_at:   2026-08-16T16:23:34-07:00
-->

# Rename Annotation to Guideline

AS a developer reading the style layer

I WANT the base class of the sixty-two guideline classes to be called `Guideline`

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
takes the name that matches the role it plays in sixty-two of its
sixty-three appearances.

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
- All 62 classes in `Style::Guidelines` load and descend from
  `Style::Guideline`, whether they name it directly (44 of them) or inherit
  through an intermediate guideline base class such as `MinimumThreshold`,
  `NoParallelPerfect`, `NoteCountPerBar`, `DirectionChanges`, `FirstBarEntry`,
  `DirectionalStepToFinalNote`, or `WeakBeatDissonanceTreatment` (18 of them).
  `Style::Guidelines` has **63 constants: 62 classes and one module**,
  `DissonanceFigureDetection`, which is a mixin and has no superclass to rename.
- `Style::Guide::ALL` has 23 entries (17 guide classes plus 6 contour
  configurations) totalling 304 ruleset entries, unchanged.
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
- `references/fourth-species-counterpoint.md` no longer instructs contributors to
  subclass `Style::Annotation`. CLAUDE.md directs contributors to `references/`
  when modifying style guidelines, so a stale sample there actively misinstructs.
- `HeadMusic::Notation::ABC::Header#annotations` and the MusicXML `beam_annotations`
  plumbing are untouched. They are unrelated domain vocabulary, not this class.

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

Three commits. A throwaway oracle script proves "no behavior change" beyond
"the suite passes."

### Verified baseline

Measured, not assumed:

| Fact | Value |
| --- | --- |
| `Style::Guidelines` constants | 63 = **62 classes + 1 module** (`DissonanceFigureDetection`) |
| Inheritance split | 44 direct + 18 indirect |
| `Guide::ALL` | 23 entries (17 classes + 6 contour configs), 304 ruleset entries |
| `Annotation` occurrences | 48 in `lib/`, 12 in `spec/` |
| Lowercase in style layer | `annotation` 7 lib / 81 spec; `annotations` 8 lib / 15 spec |
| String literals containing `Annotation` | 0 |
| Unqualified `Guidelines::` references | 0 — so `Guideline`/`Guidelines` cannot resolve ambiguously |
| i18n keys mentioning annotation | 0 |
| `.rubocop_todo.yml` | does not exist |

### Step 1 — Capture the behavioral oracle, before touching anything

Cannot be reconstructed afterward. It references no renamed constant, so the
same script runs on both trees. Keep it in a scratchpad, never in the repo:
`head_music.gemspec:25` builds `spec.files` from `git ls-files`, so an untracked
file cannot leak into the gem.

> **Already captured during planning**, and verified still valid: `lib/` and
> `spec/` are untouched since it ran, and `coverage/.last_run.json` was cleaned up.
>
> ```
> <session-scratchpad>/style_baseline.rb
> <session-scratchpad>/before.json   # 2,622 rows · 23 guides · 174 distinct fitness values
> ```
>
> Re-run it if the scratchpad has been cleaned, or if anything under `lib/` or
> `spec/` changes before the rename begins — a baseline taken after the first
> edit proves nothing.

```ruby
$LOAD_PATH.unshift File.expand_path("lib", Dir.pwd)
$LOAD_PATH.unshift File.expand_path("spec", Dir.pwd)
require "head_music"; require "composition_context"; require "spec_helper"; require "json"

contexts = []
%w[fux_cantus_firmus_examples clendinning_cantus_firmus_examples
   schoenberg_cantus_firmus_examples davis_and_lybbert_cantus_firmus_examples
   fux_cantus_firmus_examples_with_errors fux_first_species_examples
   clendinning_first_species_examples davis_and_lybbert_first_species_examples].each do |m|
  Array(send(m)).each_with_index { |ctx, i| contexts << ["#{m}-#{i}", ctx] }
end

rows = HeadMusic::Style::Guide::ALL.flat_map do |guide|
  key = HeadMusic::Style::Guide.key_for(guide)
  contexts.flat_map do |label, ctx|
    ctx.composition.voices.each_with_index.map do |voice, vi|
      a = HeadMusic::Style::Analysis.new(guide, voice)
      {guide: key, corpus: label, voice: vi,
       fitness: a.fitness.round(12), adherent: a.adherent?, messages: a.messages.sort,
       items: a.annotations.map { |x|
         [x.class.name.split("::").last, x.fitness.round(12),
          x.weight, x.gate?, [x.marks].flatten.compact.size]
       }.sort_by(&:first)}
    end
  end
end
File.write(ARGV[0], JSON.pretty_generate(rows))
```

Produces 2,622 rows across 23 guides, with 174 distinct fitness values and 1,509
non-adherent rows — it discriminates rather than printing 1.0 everywhere, and it
is byte-identical across repeat runs. `.round(12)` kills float-formatting noise;
`.sort` kills incidental ordering. Capturing per-item `weight`/`gate?`/mark-count
catches a regression that would cancel out at the `Analysis#fitness` level.

> **Gotcha:** `require "spec_helper"` starts SimpleCov, which overwrites
> `coverage/.last_run.json` with `{"line":100.0,"branch":100.0}`. A later
> `bundle exec rake` then measures ~97.75% branch coverage against that bogus
> baseline and trips `maximum_coverage_drop 1.0` (`spec/spec_helper.rb:27`),
> failing for no real reason. Run `rm -f coverage/.last_run.json` before the
> final `bundle exec rake`.

### Step 2 — Drop the `annotation_messages` alias

Delete `alias_method :annotation_messages, :messages` at
`lib/head_music/style/analysis.rb:23` **by hand**. All 12 call sites are the
byte-identical line `its(:annotation_messages) { are_expected.to include(expected_message) }`:

- `spec/head_music/style/guides/fux_cantus_firmus_spec.rb:43,61`
- `spec/head_music/style/guides/first_species_melody_spec.rb:31,49,67`
- `spec/head_music/style/guides/first_species_harmony_spec.rb:113,131,149`
- `spec/head_music/style/guides/salzer_schachter_cantus_firmus_spec.rb:33,51,69,87`

```bash
rg -l 'annotation_messages' spec | xargs sed -i '' 's/annotation_messages/messages/g'
```

**Do not include `lib` in that path list.** sed would rewrite line 23 into
`alias_method :messages, :messages` — legal Ruby that passes the suite silently
while leaving dead code.

Gate: `rg -c annotation_messages lib spec` finds nothing; suite green.

### Step 3 — The rename (riskiest step, must land atomically)

```bash
git mv lib/head_music/style/annotation.rb       lib/head_music/style/guideline.rb
git mv lib/head_music/style/annotation          lib/head_music/style/guideline
git mv spec/head_music/style/annotation_spec.rb spec/head_music/style/guideline_spec.rb

rg -l 'HeadMusic::Style::Annotation' lib spec \
  | xargs sed -i '' 's/HeadMusic::Style::Annotation/HeadMusic::Style::Guideline/g'
```

BSD `sed -i ''` — the empty backup suffix is mandatory on macOS. No word boundary
needed: the literal is unambiguous and rewrites `...::Annotation::Configured`
correctly in the same pass, since only the prefix changes.

**What the command misses — mandatory manual follow-up:**

- **Three bare `Annotation` references** with no `HeadMusic::Style::` prefix.
  Find with `rg -n 'Annotation' lib spec | grep -v 'HeadMusic::Style::Annotation'`:
  - `lib/head_music/style/annotation.rb:1` — the class comment
  - `lib/head_music/style/guides/configured.rb:6` — "`Annotation::Configured` quacks like…"
  - `spec/spec_helper.rb:36` — "Matcher for a guideline wrapped by `Annotation.with(...)`"
- **The two `require` lines**, `lib/head_music.rb:185-186`, which carry the
  lowercase *path*, not the constant. Position unchanged, between `style/analysis`
  (:184) and `style/mark` (:187). Missing these is a loud `LoadError`.

**Why this step is riskiest.** `spec/spec_helper.rb:58` *reopens* the class. If
the rename lands in `lib/` but that line is missed, Ruby does not raise —
`class A::B` with `B` undefined silently defines a new empty class. The four
helpers attach to a stillborn `Style::Annotation` and 17 spec files fail with
`undefined method 'marks_count'`, pointing nowhere near the cause. Sweeping
`lib` and `spec` in one pass covers it automatically.

Gate: `rg -n 'Annotation' lib spec` empty; `rg -n 'style/annotation' lib spec`
empty; suite green; `bundle exec rubocop` clean — rubocop-rspec's
`SpecFilePathFormat` fails if the spec file move was skipped, which is a free check.

### Step 4 — Lowercase vocabulary and docs

Three categories, resolved by *scope* rather than per-site judgment:

| | Where | Decision |
| --- | --- | --- |
| **A** — the surviving `Analysis#annotations` reader | `style/analysis.rb:21,25,26,33,39,49,57`; `analysis_spec.rb:19,37,57,104`; `guides/contour_melody_spec.rb:158,236,251,285,290,318,421`; `guides/configured_spec.rb:56` | **stays** |
| **B** — names a `Guideline` instance (locals, block params, `subject(:annotation)`) | ~81 singular sites in `spec/head_music/style/`, 7 in `lib/head_music/style/` | **rename** to `guideline` |
| **C** — unrelated domain vocabulary | `notation/abc/header.rb:11,17,76`, `abc/parser.rb:51`, `music_xml/{beam_grouper,note_writer,render_plan}.rb`, `content/comment.rb:4`, 4 notation specs | **never touch** |

Category C is the landmine: `ABC::Header#annotations` is a published public reader
for ABC `N:` fields, and `beam_annotations` is MusicXML plumbing. A repo-wide
lowercase replace breaks shipped API. **Scoping every lowercase pass to
`lib/head_music/style/` and `spec/head_music/style/` protects Category C
automatically** — that is the whole rule.

The collision shape, receiver stays and block param renames:

```ruby
# spec/head_music/style/analysis_spec.rb:57
expect(analysis.annotations.any? { |guideline| !guideline.adherent? }).to be true
```

Same at `contour_melody_spec.rb:237,286,290-291,318-319` and `style/analysis.rb:53`.

Plural prose meaning the *base class* (rename): `style/mark.rb:2`,
`guides/configured_spec.rb:36`. Meaning the *method* (leave):
`analysis_spec.rb:76`, `contour_melody_spec.rb:154`. Other lib comments:
`guides/base.rb:5`, `guides/contour_melody.rb:38`, `guidelines/singable_intervals.rb:9`,
`guidelines/large_leaps.rb:11`.

Docs: `references/fourth-species-counterpoint.md:206,208,211` carries the heading
"Guidelines: Annotation and Mark" and a live `class MyGuideline < HeadMusic::Style::Annotation`
sample. Also `CLAUDE.md:117`.

Final sweep: `rg -n '\bannotation' lib/head_music/style spec/head_music/style` —
residue should be only the Category A receivers.

### Step 5 — Verify

```bash
bundle exec rubocop -a && bundle exec rubocop
ruby $SCRATCH/style_baseline.rb $SCRATCH/after.json
diff -q $SCRATCH/before.json $SCRATCH/after.json     # must be silent
rm -f coverage/.last_run.json                        # see step 1 gotcha
bundle exec rake
```

Plus a load census in a **clean process**, since explicit ordered requires mean a
constant can appear resolvable only because another file loaded it first:

```bash
ruby -Ilib -e '
require "head_music"
g = HeadMusic::Style::Guidelines
classes = g.constants.map { |n| g.const_get(n) }.grep(Class)
abort "constants: #{g.constants.size}" unless g.constants.size == 63
abort "classes: #{classes.size}"       unless classes.size == 62
abort "orphans" unless classes.all? { |c| c <= HeadMusic::Style::Guideline }
abort "direct: #{classes.count { |c| c.superclass == HeadMusic::Style::Guideline }}" \
  unless classes.count { |c| c.superclass == HeadMusic::Style::Guideline } == 44
abort "Annotation still resolves" if HeadMusic::Style.const_defined?(:Annotation, false)
abort "alias survived" if HeadMusic::Style::Analysis.method_defined?(:annotation_messages)
abort "ruleset entries: #{HeadMusic::Style::Guide::ALL.sum { |x| x.ruleset.size }}" \
  unless HeadMusic::Style::Guide::ALL.sum { |x| x.ruleset.size } == 304
puts "OK 63/62/44 + 304 ruleset entries"'
```

The `false` inherit-flag on `const_defined?` matters — a bare `defined?` would be
satisfied via an ancestor. This check is only meaningful outside RSpec: under the
suite, a missed `spec_helper.rb:58` would have *created* the constant.

Finally, prove the diff contains only renames:

```bash
git diff -U0 -- spec/ | rg '^[-+]' | rg -v '(annotation|Annotation|guideline|Guideline|messages)'
```

Every surviving line must be a pure identifier substitution. Anything else
belongs in story 2, per this story's Notes.

**No new specs.** Under a zero-behavior-change constraint, added coverage is scope
creep; the load census is a shell check, not a committed spec. The one genuine
hole — nothing pins "62 classes descend from the base" — belongs with story 2,
where it would be load-bearing.

### Commit granularity

Three commits, split specifically to protect git's rename detection:

1. **Drop the `annotation_messages` alias** — one deleted line plus 12 identical
   one-token spec edits. Reviewable in seconds; buried in a 60-file diff otherwise.
2. **Rename `Style::Annotation` to `Style::Guideline`** — the three `git mv`s,
   ~60 constant substitutions, three bare comments, two require lines. Similarity
   ratios are 99%/97%/99%, so git renders all three as clean `rename` entries.
   Do **not** fold step 4 in: the spec file drops to ~74% similarity and the diff
   stops reading as a rename. Do **not** split the `git mv` from the content
   change either — the intermediate commit would `require` a path that no longer
   exists, breaking `git bisect`.
3. **Lowercase vocabulary, `references/`, `CLAUDE.md`** — pure churn; the reviewer
   only checks that no Category A receiver moved.

Confirm with `git diff -M --summary HEAD~3..HEAD` (three renames detected).

### Decisions taken

- **CHANGELOG.** Add a `### Changed` entry under `## [Unreleased]` for the rename
  and the dropped alias. Leave `CHANGELOG.md:20` alone — it describes
  `Guides::Configured` as "the guide-layer twin of `Annotation::Configured`" and
  came from commit `7e2ce56`, the same commit that bumped to 19.0.0, so it is
  shipped history. Rewriting it is worse than a momentarily odd-looking line.
  Lines 90/168/208 are released 17.x history; do not touch.
- **The missing `## [19.0.0]` heading is a separate chore.** 19.0.0 is published
  on rubygems and `version.rb` says `19.0.0`, but the CHANGELOG has no heading for
  it — its notes sit under `## [Unreleased]`, mixing shipped content with genuinely
  unreleased work. Not this story's problem; worth its own ticket.
- **Backlog stories citing `Annotation.with(...)`** (`sixteenth-century-style.md:19`,
  `split-counterpoint-species-by-author.md:25`) are left stale. They get rewritten
  on activation, and the epic plus `first-class-rules.md` use mapping language that
  stays correct.
- **`spec/examples.txt`** is gitignored; the spec-file rename orphans its entries,
  so `--only-failures` behaves oddly locally until a full re-run. Cosmetic.
