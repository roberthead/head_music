<!--
metadata:
  created_at:   2026-08-19T19:53:16-07:00
  activated_at: 2026-08-27T18:39:03-07:00
  planned_at:
  finished_at:
  updated_at:   2026-08-27T18:39:03-07:00
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
`guides.map(&:instruction)` but not `guide.name`, which exists. No guide name
names a note value today, so this is a blind spot rather than a miss -- and it
matters because `British Note Names` deliberately sequenced
`sixteenth-century-style.md` and `split-counterpoint-species-by-author.md`
*behind* it so that both would inherit the sweep. A new guide whose **name**
carries a note value slips past.

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
- Adding a correct new British vocabulary entry does not fail any example

## Implementation Plan

[to be filled in by /stories plan]
