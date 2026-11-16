<!--
metadata:
  created_at:   2026-11-15T20:05:00-05:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-16T10:01:05-05:00
-->

# Story: Free Species Translations

## Summary

AS a student using the gem's feedback in German, Spanish, French, Italian, or Russian
I WANT the free species guide and its guidelines in my language
SO THAT the feedback on a free species exercise doesn't drop into English

## Acceptance Criteria

- Guide instructions for `free_species`, `free_species_melody`, and `free_species_harmony` in de, es, fr, it, and ru
- Names, instructions, and violations for the guidelines the free species guide added (`FreeDissonanceTreatment`, `IndependentTextures`, `AllowFreeSpeciesRhythmicValues`, `ClausulaVera`, `BarCount`), including their configured variants, in the same locales
- Russian plural forms (one, few, many) wherever a string pluralizes on a count
- The instruction text keeps the free species framing in each language: no cantus firmus is given, and the name is the gem's own
- `guide_strings_spec.rb` passes for every locale with no fallback to English for these keys
- CHANGELOG entry under Unreleased

## Notes

Split from [free-species-guide](../current/free-species-guide.md) during its planning (2026-11-15), which followed the English-first precedent of `fifth_species` and `mix_species_textures`. Those two have the same gap and could join this story.

## Implementation Plan

[to be filled in by /stories plan]
