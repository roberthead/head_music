<!--
metadata:
  created_at:   2026-08-19T19:53:16-07:00
  activated_at: 2026-08-27T18:39:03-07:00
  planned_at:   2026-08-27T19:05:38-07:00
  finished_at:  2026-08-27T19:45:55-07:00
  updated_at:   2026-08-27T19:45:55-07:00
-->

# Story: Guard the Vocabulary Sweep Itself

## Summary

AS the next person to add a rhythmic unit or a guideline
I WANT the note-vocabulary sweep to catch a locale I forgot
SO THAT a mixed-dialect string fails a spec rather than reaching a student

## Notes

`British Note Names` added the sweep at `spec/head_music/style/guide_strings_spec.rb`
("gives every locale only the note vocabulary it owns") as the guard against its
own top-stated risk: partial coverage produces a *mixed-dialect document*, not a
partially-improved one. The sweep works, and it is written in the right shape --
ownership per locale, with `fetch` and no default, so a locale added to the gem
fails until someone decides which vocabulary it reads.

Two gaps in it are latent rather than live. Both were found reviewing that story
and neither blocked it, because nothing leaks in any locale today.

**1. The sweep cannot see a bare American word, which is the only kind the
British sentence can leak.**

`NOTE_VOCABULARIES[:american]` requires a head noun:

```ruby
american: /\b(whole|half|quarter|eighth|sixteenth)[-\s](note|rest)/i
```

That scoping is load-bearing and must stay -- "half step", "whole tone" and "half
cadence" are ordinary theory terms waiting to false-fire, and the British side
needs its `\b` for the opposite reason, since five real strings read "Minimum of
eight notes" and an unanchored `/minim/` flags every one.

But the British sentence **drops that head noun by design** -- four crotchets,
not four crotchet notes. So an American word arriving through
`%{rhythmic_unit}` arrives bare, and the sweep is blind to exactly the leak the
noun-drop makes possible. Reproduced by adding an `eighth` unit to `en` only:

```
en    : "Use eight eighth notes in each middle bar."
en_GB : "Use eight eighth in each middle bar."
american sweep flags the en_GB string? false
```

Not a defect today -- only `whole`, `half` and `quarter` units exist
(`one_per_bar.rb`, `two_per_bar.rb`, `three_per_bar.rb`, `four_per_bar.rb`) --
but it bites on the next unit added, and prose sweeping cannot be made to catch
it without reintroducing the false positives the scoping exists to prevent.

The fix is to guard the vocabulary by **key parity** rather than by rendered
prose, which does not depend on any sentence rendering it. `template_keys` is
already in the file:

```ruby
it "gives every English rhythmic unit a British name" do
  units = ->(locale) { template_keys(locale).grep(/\Arhythmic_units\./) }

  expect(units.call(:en) - units.call(:en_GB)).to be_empty
end
```

**2. `strings_in` does not sweep guide display names.** It collects
`guides.map(&:instruction)` but not `guide.display_name`, which exists.

The method is `display_name`, not `name`: `Guides::Base.name`, `Configured#name`
and `CompositeGuide#name` all return the Ruby class name --
`Guide::ALL.first.name` is `"HeadMusic::Style::Guides::FuxCantusFirmus"` -- so a
sweep written over `name` would sweep identifiers rather than the prose a reader
sees.

Mostly a blind spot rather than a miss, though less purely than it first looked:
`salzer_schachter_cantus_firmus` carries a real `guides.*.name` entry at
`en.yml:924` that nothing sweeps and `en_GB` does not override. No guide name
names a note value today.

It matters for `sixteenth-century-style.md` and
`split-counterpoint-species-by-author.md`, both of which add guide classes whose
humanized keys become display names. `British Note Names` sequenced those two
behind *itself*, not behind this story, so both are already unblocked -- the
relationship is coverage, not blocking. A new guide whose **display name**
carries a note value slips past until this closes.

**3. Two smaller items in the same file**, worth folding in rather than filing
separately:

- The example at `guide_strings_spec.rb:279` pins `match_array %i[whole half
  quarter]`, coupling it to today's vocabulary. Adding `quaver` later -- a
  correct change -- fails it with a message that reads like a regression. The
  key-parity guard above carries the intent without the coupling.
- The comment above `"walks the British plural entries it is guarding"` says it
  "proves it fires at the real tree", but the example never calls
  `partial_plurals_in`. It proves the tree that guard walks is non-empty and
  well-formed, which is the useful thing; only the wording overclaims.

## Acceptance Criteria

- A rhythmic unit added to `en.yml` without a British counterpart fails a spec,
  and the failure names the unit
- The guard does not depend on a sentence interpolating the unit, since the
  leaking sentence is the one that drops the noun
- A guide whose display name carries a note value is swept like its instruction
- The existing prose sweep keeps its `note|rest` scoping and its British word
  boundary -- both prevent real false positives, and neither should be widened
  to chase this
- No example hardcodes the list of rhythmic units; adding a correct new British
  vocabulary entry changes no assertion

## Implementation Plan

### Scope

Every change that ships is in one file, `spec/head_music/style/guide_strings_spec.rb` — no `lib/` and
no locale change. (Drills 4 and 5 under Testing Strategy edit `en.yml` and `en_GB.yml` temporarily and
revert.) Baseline is 25 examples, 0 failures; this plan lands at 31.

Line numbers throughout are as the file stands today. They shift as steps land, so anchor each edit on
the example name or method it belongs to rather than on the number.

The `display_name`-not-`name` correction and the already-unblocked dependency reading are folded into
Notes item 2 rather than repeated here. Two verified facts shape the work:

- All 30 guide display names are byte-identical across all eight locales, and none matches either
  vocabulary regex. So widening `strings_in` breaks neither line 128 nor lines 202-203.
- No string in any locale contains a doubled space, a space before punctuation, or leading/trailing
  whitespace today, so the step 7 blank-interpolation check starts green.

Decisions taken before planning closed, recorded so implementation does not reopen them:

- The AC-4 pattern guards (step 4), the `problems_in` sibling fix (step 1b) and the comment accuracy
  pass (step 6) are all in scope.
- The empty-value hole is closed in `fault_in` for every string (step 7), not scoped to the
  `rhythmic_units` subtree — the hole is `fault_in`'s, not the vocabulary's.
- The AC-4 examples live in-file beside the sweep at line 137, not in a nested `describe`.
- Line 79's `eq 30` / `eq 67` is commented, not decoupled (step 6).
- `unnamed_rhythmic_units` takes keyword arguments (step 3).

### Step 1 — Sweep the guide's display name in both collectors

Widen `strings_in` (line 84) so the vocabulary sweep, the `de`/`en_GB` equality and the `en_US`/`es`
equality all see guide names. Put it in the **shared** `strings_in`, not in a private collector for the
sweep alone: the remedy for a note-value guide name is a British `guides.<key>.name` override, and
lines 128 and 202-203 are the only things that would check such an override landed in the right file
and that `de` inherits it. `strings_in` already collects `item.name` at line 87 — omitting the guide's
own name was an oversight, not a decision.

```ruby
# display_name, not name: Base.name, Configured#name and CompositeGuide#name
# all return Ruby class names, so sweeping name would sweep identifiers rather
# than the prose a reader sees.
#
# Shared with the two locale-equality examples on purpose. The day a locale
# gets its own guides.<key>.name, they are what checks it landed in the right
# file and that de inherits it -- so the fix for a failure there is to move a
# row, not to loosen the example.
def strings_in(locale)
  I18n.with_locale(locale) do
    guides.flat_map { |guide| [guide.display_name, guide.instruction] } +
      items.flat_map { |item| [item.name, item.instruction] + item.violation_previews }
  end
end
```

Make the same fix in the sibling collector `problems_in` at line 43, so it mirrors the `items` line
directly below it:

```ruby
guides.flat_map { |guide| %i[display_name instruction].filter_map { |m| problem_with(guide, m) } } +
```

No acceptance criterion demands this second change, but it is the same omission in the same pair of
collectors and it closes a real hole: `Guide.display_name_for` (`lib/head_music/style/guide.rb:107`)
bypasses `Style::Template` and carries an `I18n.translate default:`, so a mistyped or missing
`guides.<key>.name` silently humanizes instead of surfacing — the one string in the file that can go
wrong without anything noticing.

Interpolation is a second, weaker reason. No `guides.*.name` interpolates today (the only one is
`salzer_schachter_cantus_firmus`, a plain string), but `guidelines.contoured.name` — `"%{contour}
contour"` at `en.yml:599`, under `guidelines:`, not `guides:` — shows the pattern is already in use one
namespace over. A guide name that adopted it would raise `I18n::MissingInterpolationArgument`, which
`problem_with`'s rescue turns into a named failure rather than a crash.

The second paragraph of that comment is the load-bearing part: once anyone adds a locale-specific
`guides.<key>.name`, the two equality examples start policing it. That is the feature — line 200's own
comment says it is pinned so a change "fails here rather than reaching a reader" — but it will
surprise whoever adds a Spanish guide name.

### Step 2 — Prove the display-name sweep (AC 3)

Split `foreign_vocabulary_in` (line 140) so the pattern can be run over a fixture — the same seam that
gives `partial_plurals_in` its companion. Insert both examples after line 138, helpers below them:

```ruby
# The sweep reads whatever strings_in collects, so a guide whose name carried a
# note value would pass unless the names are in that list. They were not: the
# sweep read instructions only. See strings_in for why it is display_name.
it "sweeps the guide names a reader sees, not only the instructions" do
  names = I18n.with_locale(:en_GB) { guides.map(&:display_name) }

  expect(names - strings_in(:en_GB)).to be_empty
end

# And that a name is worth sweeping. A guide with no name entry renders the
# humanized key, which is locale-independent, so a guide keyed
# whole_note_species reads "Whole Note Species" to a British student too. The
# remedy is a guides.<key>.name in en.yml and its British override in
# en_GB.yml; this says the sweep will ask for them.
it "would catch an American note value in a guide name" do
  expect(foreign_vocabulary_among(["Whole Note Species"], :en_GB)).not_to be_empty
end

def foreign_vocabulary_in(locale) = foreign_vocabulary_among(strings_in(locale), locale)

def foreign_vocabulary_among(strings, locale)
  foreign = NOTE_VOCABULARIES.except(LOCALE_NOTE_VOCABULARY.fetch(locale))
  strings.flat_map do |string|
    foreign.filter_map { |family, pattern| "#{locale}: #{family} in #{string.inspect}" if pattern.match?(string) }
  end
end
```

The humanized-default reasoning was checked directly, not inferred:
`I18n.with_locale(:en_GB) { Guide.display_name_for(:whole_note_species) }` returns `"Whole Note
Species"`, as does `:de`. A British `guides.<key>.name` override is indeed the remedy — and it must be
added to **both** `en.yml` and `en_GB.yml`, since an `en_GB`-only entry fails the line-173 guard.

### Step 3 — Add the rhythmic-unit key-parity guard and its companion (AC 1, AC 2, AC 5)

Insert after line 175, immediately below the mirror-direction guard it pairs with:

```ruby
# The mirror, and the one guard the prose sweep cannot be. The American
# pattern needs a note|rest head noun, and the British sentence drops that
# noun by design -- four crotchets, not four crotchet notes -- so a unit with
# no British name reaches a British reader as a bare "eighth" that no
# vocabulary pattern can flag without also flagging "half step".
#
# Scoped to rhythmic_units rather than run as a blanket english - british:
# en_GB overrides only the entries whose wording differs, so a blanket diff is
# hundreds of keys long by design. These are the entries where an English key
# with no British counterpart is a leak rather than an inheritance.
it "gives every English rhythmic unit a British name" do
  expect(rhythmic_unit_keys(english_template_keys)).not_to be_empty
  expect(unnamed_rhythmic_units(english: english_template_keys,
                                british: british_template_keys)).to be_empty
end

# Proves the diff fires, which the guard above cannot: it asserts an absence,
# and a prefix that stopped matching the tree reports the same absence. Given
# inline rather than by injecting a key into the real list, so that a real gap
# cannot report itself twice, and so the fixture can also show the scoping --
# the guideline key below is unmatched in British on purpose and is ignored.
it "would catch a rhythmic unit added to English alone" do
  english = ["rhythmic_units.whole", "rhythmic_units.eighth", "guidelines.no_rests.name"]
  british = ["rhythmic_units.whole"]

  expect(unnamed_rhythmic_units(english: english, british: british)).to eq ["rhythmic_units.eighth"]
end
```

Add the helpers after line 196 (`english_template_keys`), keeping the key readers together:

```ruby
def rhythmic_unit_keys(keys) = keys.grep(/\Arhythmic_units\./)

# Keywords, not positional: swapped arguments would invert this into the
# guard at line 173 and stay green over a real gap.
def unnamed_rhythmic_units(english:, british:)
  rhythmic_unit_keys(english) - rhythmic_unit_keys(british)
end
```

**AC 1 is satisfied by `be_empty` as written — do not build a custom matcher.** Seeding
`eighth: "eighth"` into a scratch `en.yml` produces exactly one failure:
``expected `["rhythmic_units.eighth"].empty?` to be truthy, got false``. Keep the full
`rhythmic_units.` prefix, which is greppable in a way a bare `eighth` is not. Two alternatives were
ruled out by running them: `be_in` is unavailable (no ActiveSupport — every element fails with
`expected "rhythmic_units.half" to respond to 'in?'`), and a custom failure message is a register this
file does not use in 299 lines.

The inline fixture pair is deliberate. The cheaper-looking `english_template_keys +
["rhythmic_units.eighth"]` is a trap: with a real gap present it reports `["rhythmic_units.eighth",
"rhythmic_units.eighth"]` and fails alongside the guard, so one cause produces two failures, one of
them confusing. The "is the real tree still there" job is instead carried by the guard's own first
line.

### Step 4 — Guard the vocabulary patterns themselves (AC 4)

AC 4 is currently unfalsifiable: nothing fails if someone widens the American pattern, which is the
exact mistake the criterion exists to prevent. Two cheap examples close it from both sides. Place both
next to the sweep at line 137.

The false-positive side — the terms the scoping exists to spare:

```ruby
# Both patterns are deliberately narrow, and nothing else says so. Widening
# either re-introduces a false positive that real strings trip today.
it "spares the theory terms the scoping exists to protect" do
  expect("Approach the half step by contrary motion.").not_to match NOTE_VOCABULARIES[:american]
  expect("Minimum of eight notes.").not_to match NOTE_VOCABULARIES[:british]
  expect("Sixteenth Century Cantus Firmus").not_to match NOTE_VOCABULARIES[:american]
end
```

The third line is dated, not hypothetical: `user-stories/backlog/sixteenth-century-style.md` adds
`SixteenthCenturyCantusFirmus`, whose humanized display name is `"Sixteenth Century Cantus Firmus"` —
which clears the American pattern **only** because of the `note|rest` head noun. Widen the pattern and
that guide false-fires in every American locale the day that story ships. Combined with step 1, this
is the concrete argument for AC 4.

The true-positive side — this file's own principle at line 263 applied to the sweep itself. Break the
American pattern to `/zzz/` today and line 137 stays green forever:

```ruby
# The sweep asserts an absence, and a broken pattern reports the same absence.
# Each locale must actually carry its own family somewhere.
it "recognizes each locale's own note vocabulary" do
  silent = LOCALE_NOTE_VOCABULARY.reject do |locale, family|
    strings_in(locale).any? { |string| NOTE_VOCABULARIES.fetch(family).match?(string) }
  end

  expect(silent.keys).to be_empty
end
```

Verified passing today.

### Step 5 — Decouple line 279 and correct the line-271 comment (story item 3)

```ruby
# And that the tree that guard walks is really there and well formed, which
# the guard cannot say either. The vocabulary entries are the only pluralized
# British data, so a typo that dropped rhythmic_units entirely would leave it
# green over nothing -- passing for the reason it passed before there was any
# British plural data at all.
#
# Says every unit rather than naming today's three: which units exist is the
# vocabulary's business, and pinning the census turns adding quaver -- a
# correct change -- into a failure that reads like a regression.
it "walks the British plural entries it is guarding" do
  british = I18n.backend.send(:translations).fetch(:en_GB).dig(:head_music, :style) || {}
  units = british.fetch(:rhythmic_units)

  expect(units).not_to be_empty
  expect(units.values).to all be_a(Hash)
  expect(units.values.map(&:keys)).to all match_array ENGLISH_PLURAL_KEYS
end
```

The replacement is strictly stronger than what it replaces, checked against four mutations: the old
form fails when the eighth unit is added correctly — keyed `eighth`, named "quaver", so the failure
reads `the extra elements were: [:eighth]`, which is the AC 5 violation — while the new one passes; the new form still fails when a unit is left scalar, when a unit carries
only `other:`, and over an empty tree.

It drops the `select { |_unit, forms| forms.is_a?(Hash) }` filter deliberately — that filter silently
excused a scalar entry, and `all be_a(Hash)` now catches it. The separate `be_a(Hash)` line exists so
a scalar fails readably instead of as `NoMethodError` on `"crotchet".keys`. `RSpec/MultipleExpectations`
is disabled at `.rubocop.yml:31`, so three expectations is in-config.

Trade-off accepted: this now forbids any non-unit scalar key ever nested under `rhythmic_units` in
`en_GB`. Correct for note values, since English pluralization always yields one/other.

### Step 6 — Comment accuracy pass in the region already being touched

Three real drifts beyond the one the story names:

- **Line 38** — the comment reads "8 locales x (23 guides + 67 items x 3 templates)". There are **30**
  guides, pinned at line 80 by the very next example. The `67` is still correct. Straight numeric
  drift.
- **Lines 283-287** — one unbroken comment block sits above two examples and describes them in reverse
  order. Sentences 1-2 ("The Ruby fallback exists so a language with no plural data reads a little
  wrong instead of raising...") describe the example at line 292; sentences 3-4 ("What the load-time
  check found, kept rather than discarded...") describe line 288's `PLURAL_GAPS`. Reads as a merge
  artifact, and line 292 currently has no comment of its own. Split the block, one half over each.
- **Lines 79-82**, `it "covers every registry entry"` — the only example in the file with no comment at
  all, and a bare `eq 30` / `eq 67` tripwire. It fails as `expected: 30, got: 31` on the very next
  story that adds a guide, which reads like a regression rather than "update the canary."

  Comment it; do **not** decouple it the way step 5 decouples line 279. The two look like the same
  coupling and are not: line 279's census was incidental to that example's job, so pinning it bought
  nothing and cost a false regression, while line 80's exact numbers *are* the example's job — it
  exists to make a human notice that the registry grew, so that the new guide's strings get swept.
  Loosening it to `not_to be_empty` would delete its reason to exist. The comment says which kind it
  is:

  ```ruby
  # A canary, not a census: these numbers are meant to fail when a guide or
  # item is added, so that the addition is noticed and its strings get swept.
  # Update them; do not loosen them. Contrast the vocabulary census below,
  # which pinned a list that was never this example's business.
  it "covers every registry entry" do
  ```

### Step 7 — Catch a blank interpolation in `fault_in`

`leaf_paths` returns a path for any non-Hash including `""`, so `quaver: ""` passes the step-3 key
parity. `fault_in` (line 65) misses it too: the sentence renders `"Use eight  in each middle bar."`,
which is neither empty nor interpolation-bearing. Closed for every string rather than for the
`rhythmic_units` subtree, because the hole is `fault_in`'s, not the vocabulary's — any template whose
value goes blank renders the same way.

```ruby
# An interpolation filled with an empty value leaves its surrounding space
# behind: "Use eight %{rhythmic_unit} in each bar" becomes "Use eight  in each
# bar", which is neither empty nor interpolation-bearing and so passes every
# check above. A blank rhythmic unit is the way this arrives -- key parity sees
# a present key, and the sentence still reads as a sentence.
return "#{label} rendered a blank value: #{rendered.inspect}" if rendered.match?(/\s\s|\s[.,;:]/)
```

Add it to `fault_in` after the interpolation check. Both alternations are load-bearing: the doubled
space catches a blank in the middle of a sentence, and the space-before-punctuation catches a blank at
the end of one (`"Write in %{rhythmic_unit}."` → `"Write in ."`).

Verified clean before writing: across all eight locales, over guide display names, guide instructions,
item names, item instructions and every violation preview, there are zero doubled spaces and zero
spaces before punctuation. The check starts green and runs against real data on day one.

(As planned, this paragraph dismissed anchoring — `\A\s|\s\z` — as guarding a case that could not
arise. The review overturned that: two swept templates *begin* with an interpolation
(`"%{number} %{rhythmic_unit} per bar"`, `"%{contour} contour"`), so a blank value there leaves only
a leading space, which the interior-only form misses. Zero strings carry leading or trailing
whitespace today, so anchoring was safe to add, and the shipped regex is
`/\s\s|\s[.,;:]|\A\s|\s\z/`.)

This rides on `problems_in`, which step 1b widens to include guide display names, so the new check
covers those too.

### Testing Strategy

This story is entirely test work, so the strategy is how each new guard is demonstrated to fire. The
file's convention — an absence-assertion gets a companion running the detector over a fixture — is
followed rather than relying on manual drills.

| Guard | How it is proven to fire |
| --- | --- |
| Rhythmic-unit key parity | Companion example over an inline key pair (step 3). Also drilled against real data: seeding `eighth` into a scratch `en.yml` gave one failure naming `rhythmic_units.eighth`. |
| Guide display names swept | Reverting the `strings_in` change with the new example in place fails it — verified. |
| A note value in a guide name is caught | Companion over `["Whole Note Species"]` through `foreign_vocabulary_among` (step 2), plus the direct check that `display_name_for(:whole_note_species)` renders American in `en_GB`. |
| Patterns not broken / not widened | Both directions pinned as examples in step 4, rather than left to review. |
| A blank unit value | Not example-pinned: `fault_in` runs over every real string in every locale, and the check was verified clean before being added. Drill 5 with `eighth: ""` instead of a real British name shows it firing. |
| `en_GB` plural completeness | Existing companion at line 265 untouched; the step-5 replacement keeps the non-emptiness and well-formedness job. |

Verification, in order:

1. `bundle exec rspec spec/head_music/style/guide_strings_spec.rb` → **31 examples, 0 failures** (25
   today, +6: two each from steps 2, 3 and 4;
   step 7 adds a clause to `fault_in`, not an example). A single-file run trips SimpleCov's 90% minimum and exits 2 — existing behavior on
   `main`, not a spec failure.
2. `bundle exec rubocop -a spec/head_music/style/guide_strings_spec.rb` → clean.
3. `bundle exec rake` for the full suite and coverage.
4. **AC 1 drill** (one-time): add `eighth: "eighth"` under `rhythmic_units:` at
   `lib/head_music/locales/en.yml:583`, run, expect exactly one failure naming `rhythmic_units.eighth`,
   revert.
5. **AC 5 drill** (one-time): add that `eighth` plus `eighth: {one: quaver, other: quavers}` under
   `lib/head_music/locales/en_GB.yml:29`, run, expect 31/0, revert.

Drills 4-5 must edit real repo files: Bundler's `gemspec` directive puts the repo `lib` first on
`$LOAD_PATH`, so the I18n backend always reads the repo's locale files regardless of load-path
manipulation. With AC 5 reworded to the greppable form, drill 5 is corroboration rather than the sole
evidence — step 5 is what satisfies the criterion, and reading the file is what verifies it. Run the
drill anyway and record the result; it is cheap and it is the only thing that exercises both locale
files together.

Drill results, recorded 2026-08-27 at implementation:

- **Drill 4 (AC 1)** — `eighth: "eighth"` added to `en.yml` alone: exactly one failure, from
  `"gives every English rhythmic unit a British name"`, reading
  `` expected `["rhythmic_units.eighth"].empty?` to be truthy, got false ``. Reverted.
- **Drill 5 (AC 5)** — the same `eighth` plus `eighth: {one: quaver, other: quavers}` in `en_GB.yml`:
  31 examples, 0 failures. No assertion anywhere noticed the correct addition. Reverted.
- **Blank-value drill (step 7)** — `en_GB.yml`'s `quarter:` plural hash replaced with `quarter: ""`:
  the new `fault_in` check fired with named strings — `"Four  per bar"`,
  `"Use three  in each middle bar."` — in every British-reading locale. Reverted.
- Full suite after all reverts: 6836 examples, 0 failures, coverage threshold met.

### Risks and Notes

No open questions remain; the decisions are listed under Scope above.

- **Forward dependency worth recording:** `user-stories/backlog/note-values-in-each-language.md` gives
  `de`, `fr`, `it`, `ru` their own vocabularies. The new key-parity guard will then need to become
  per-locale-pair rather than en-vs-en_GB, with `LOCALE_NOTE_VOCABULARY` as the natural driver.
  Generalizing now would parameterize over locale data that does not exist, so the guard would assert
  nothing — but recording the direction saves rediscovering it.
- **Rejected edge cases, with reasons rather than "out of scope":**
  - *Reverse direction* — line 173 already covers `rhythmic_units.*` in the `british - english`
    direction; computed, and it is `[]`. Add a one-line comment on the new guard pointing at line 173
    so the next reader does not add the mirror.
  - *`guides.<key>.name` key parity* — guide and guideline names carry the head noun (`"Minims in the
    first bar"` / `"Half notes in the first bar"`), so the prose sweep catches them once step 1 lands.
    The noun-drop that defeats prose sweeping is unique to `%{rhythmic_unit}` interpolation, and the
    only name that interpolates it (`note_count_per_bar.name`, `en_GB.yml:73`) already routes through
    the `rhythmic_units` table this guard covers.
  - *Extend parity past `rhythmic_units`* — `en` has 212 style template keys, `en_GB` has 42, and
    `en - en_GB` is 170; `en_GB` is deliberately a partial override, so a blanket parity guard would
    assert something **false**, not merely broad.
  - *A shared helper for the two parity examples* — they are not mirror images: different direction
    *and* different scope, so a shared helper would take both as parameters and read worse than two
    short examples. `template_keys` is already the right amount of shared abstraction.

## Review

Reviewed 2026-08-27 at commit `1a44754`, plus two post-review fixes now in the working tree
(uncommitted). Reviewers: product-manager (acceptance criteria, drills re-run independently) and
code-reviewer (spec correctness, comment accuracy, false-positive analysis), run in parallel.
Baseline both confirmed: 31 examples, 0 failures; rubocop clean.

### Acceptance criteria

- ✅ **A rhythmic unit added to `en.yml` without a British counterpart fails a spec, and the failure
  names the unit** — drill re-run independently, not taken from this file: `eighth` in `en.yml` alone
  gives exactly one failure, from `"gives every English rhythmic unit a British name"`, reading
  `` expected `["rhythmic_units.eighth"].empty?` to be truthy ``.
- ✅ **The guard does not depend on a sentence interpolating the unit** — `unnamed_rhythmic_units`
  diffs `template_keys`, which `YAML.load_file`s the locale files directly; no rendering anywhere on
  the path. The AC 1 drill doubles as proof: no sentence interpolates an `eighth` unit today, and the
  guard fired anyway.
- ✅ **A guide whose display name carries a note value is swept like its instruction** — `strings_in`
  collects `guide.display_name`; the live sweep routes through it; one example pins names ⊆ swept
  strings and another proves `"Whole Note Species"` is flagged in `en_GB` through the same helper the
  sweep uses.
- ✅ **The prose sweep keeps its `note|rest` scoping and its British word boundary** —
  `NOTE_VOCABULARIES` verified byte-identical to the merge-base by direct comparison. Now falsifiable
  from both sides: the spared-terms example pins the false positives the narrowness prevents
  ("Minimum of eight notes." survives only the `s?\b`; "Sixteenth Century Cantus Firmus" only the
  head noun), and `"recognizes each locale's own note vocabulary"` pins that each family actually
  matches — 38 matches per locale, so a pattern broken to `/zzz/` cannot report a clean absence.
- ✅ **No example hardcodes the list of rhythmic units; a correct addition changes no assertion** —
  the census is gone; drill re-run: `eighth`/`quaver` in both files gives 31/0. Remaining literal
  units (two verbatim-sentence pins, one inline fixture) are not censuses and did not move.

Scope beyond the criteria — the `fault_in` blank check, the `problems_in` widening, the comment
fixes — was all pre-declared in the plan and verified working. No criterion's evidence is weaker
than this file claims; every recorded drill reproduced exactly.

### Code review findings

1. **(Important — fixed)** The blank-value check missed a blank interpolation in leading or trailing
   position: both alternations required whitespace adjacent to other content, while
   `"%{number} %{rhythmic_unit} per bar"` and `"%{contour} contour"` open with an interpolation, so a
   blank there leaves a single leading space. Verified through the real render path
   (`" crotchets per bar"` → no fault). This overturned the plan's own dismissal of anchoring, which
   claimed the case could not arise. Fixed: the regex is now
   `/\s\s|\s[.,;:]|\A\s|\s\z/`, safe because zero strings carry edge whitespace today, and the
   comment names the leading-interpolation template that motivates the anchors.
2. **(Important — fixed)** The scale comment's arithmetic went stale in this very branch: widening
   `problems_in` to two strings per guide made "30 guides" undercount its own collector. Now reads
   `30 guides x 2 + 67 items x 3 templates` (measured: 262 strings per locale).
3. **(Note, no action)** French typography cannot false-trip the blank check: Ruby's `\s` is
   ASCII-only, so the non-breaking spaces correct French puts before `:` and `;` are invisible to it,
   and `!`/`?` are not in the punctuation class. The residual case — a plain-ASCII space before `:`
   in a future `fr` style entry — becomes live only when note-values-in-each-language lands. Recorded
   in the spec comment.
4. **(Note, no action)** Widening `problems_in` to `display_name` quietly closed a fourth hole: raw
   `I18n.translate` with a `default:` bypasses every `Template` guard, so an interpolation added to a
   `guides.<key>.name` would have shipped unrendered; the `include?("%{")` check now catches it.

Every new example was checked for vacuous or wrong-reason passes; none found. All new and edited
comments verified against the code they describe. Nothing blocks `finish`.

## Learnings

- **The story's own Notes carried a wrong method name, caught only by running code.** Item 2 said to
  sweep `guide.name`; that returns the Ruby class name, and the method a reader sees is
  `display_name`. A sweep written from the Notes as filed would have swept identifiers and passed
  vacuously. Every load-bearing claim in a story should be executed once before it becomes a plan.
- **Verification discipline paid for itself twice more.** Planning ran each proposed formulation
  against mutated locale data, so implementation was nearly transcription — 31/0 on the first run.
  And the review's product-manager re-ran every drill independently; all three reproduced exactly,
  which is what made "all criteria met" a finding rather than a claim.
- **A verified plan still shipped one wrong dismissal — of the exact shape the story warns about.**
  The plan rejected anchoring the blank-value regex because "the case cannot arise today," but the
  evidence checked a neighboring property (no string has edge whitespace) rather than the case itself
  (templates that *open* with an interpolation, of which two exist). When dismissing an edge case,
  verify the case, not its neighbor. The review caught it; the fix was one alternation.
- **Guarding a guard means making its narrowness falsifiable.** AC 4 ("keep the scoping, don't widen
  it") was unenforceable as written — nothing failed if someone widened the regex. Two cheap examples
  turned the criterion from a review note into a test: pin what the narrowness spares, and pin that
  each pattern still matches its own family somewhere.
- **Not all count-coupling is the same defect.** The census at the old line 279 and the `eq 30`
  canary at line 80 looked identical; one was incidental coupling to decouple, the other is the
  example's entire job and got a comment instead. Worth distinguishing explicitly before "fixing"
  either.
- **Drills must mutate the value, not the template.** One drill edited `%{number}` out of a template
  and proved nothing — the leak shape is a *blank interpolated value*, which renders differently.
  Also practical: Bundler's `gemspec` load path means drills must edit the real locale files;
  scratch-tree copies are never read.
- **Deciding open questions before implementation kept it linear.** Two question rounds settled
  scope, placement, the helper signature, and an AC rewording; implementation then ran start to
  finish with nothing relitigated.
