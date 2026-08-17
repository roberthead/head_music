<!--
metadata:
  created_at:   2026-08-17T15:14:53-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-08-17T15:14:53-07:00
-->

# Story: British Note Names

## Summary

AS a British reader of a style guideline
I WANT note values named as semibreves, minims, crotchets and quavers
SO THAT the guidance reads as my teacher would say it, not as a translation

## Notes

`Guideline Strings into I18n` gave `en_GB` the five strings whose *spelling*
differs — `neighbour`, `metre`, and a bar rather than a measure. It stopped
there. British readers still get "Use four quarter notes in each middle bar."

This was left out deliberately rather than missed, because it is not the same
kind of change and it carries a live hazard.

**A vocabulary swap does not survive the sentence.** The obvious fix is to
override the three `rhythmic_units` entries — `whole`, `half`, `quarter` — and
let the templates pick them up. It does not work. The template reads:

```yaml
note_count_per_bar:
  violations:
    default:
      other: "Use %{number} %{rhythmic_unit} notes in each middle bar."
```

Substituting the vocabulary alone yields "Use four crotchet notes in each middle
bar." British drops the noun: "Use four crotchets in each middle bar." So the
`en_GB` side needs its own *sentences*, not its own words — and that is a
translation job, not a find-and-replace.

**Those sentences are pluralized, and `en_GB` sits mid-chain.** `de`, `fr`, `it`
and `ru` all resolve through `en_GB` before reaching `en`. I18n stops at a plural
hash that is present but incomplete rather than continuing past it, so a British
entry carrying only `other:` raises for those four languages and never for the
British reader who wrote it. `guide_strings_spec.rb` guards this
(`partial_plurals_in`), which is what makes the work safe to pick up — but it is
the reason not to do it in passing at the end of another story.

**Scope.** Sixteen touchpoints:

| Kind | Count | Which |
| --- | --- | --- |
| Hardcode an American note value | 12 | 5 guideline violations — `allowed_rhythmic_values_for_combined123`, `allowed_rhythmic_values_for_fifth_species`, `first_bar_half_notes`, `first_bar_quarter_notes`, `first_bar_whole_note` — and 7 of the 23 guide instructions |
| Interpolate `%{rhythmic_unit}` | 4 | `note_count_per_bar` name and violation, each `one:`/`other:` |
| Vocabulary entries | 3 | `rhythmic_units.half`, `.quarter`, `.whole` |

`rhythmic_units` has no `eighth`, though
`allowed_rhythmic_values_for_fifth_species` names eighth notes in prose. Adding
one is part of this work if the vocabulary route is taken.

Worth deciding first: whether the British vocabulary belongs to the style scope
or to `Rudiment::RhythmicUnit`, which is where the gem names these values for
every other purpose. If the latter, this story is smaller than it looks and the
notation module benefits too.

## Acceptance Criteria

- A British reader gets British note values in every style string that names one
- Every pluralized `en_GB` entry carries the complete set of forms, and the
  existing guard proves it rather than discipline
- `de`, `fr`, `it` and `ru` still render every string, since they route through
  `en_GB` — the property spec in `guide_strings_spec.rb` already covers this
- The decision about `rhythmic_units` versus `Rudiment::RhythmicUnit` is recorded
