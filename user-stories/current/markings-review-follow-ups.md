<!--
metadata:
  created_at:   2026-09-27T11:01:33-07:00
  activated_at: 2026-09-27T11:01:54-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-27T11:01:54-07:00
-->

# Story: Markings Review Follow-ups

## Summary

AS a developer or researcher using HeadMusic

I WANT the markings that the formats can express to come through a write and a read intact, and malformed markings in Flow JSON to be refused

SO THAT a dynamic is never lost without a word, a written rhythm is never rewritten to make room for one, and the open items from the markings review are closed

## Background

The review of [Articulations, Ornaments, Dynamics](../done/articulations-ornaments-dynamics.md) left several items open. Each one below was reproduced on `main` at `4ed933d5`.

- **MusicXML drops a trailing voice dynamic.** A voice `C D E` in 4/4 with a *f* placed at beat 4 writes no `<f/>`. `DirectionWriter` finds the voice event sounding at the dynamic's position, and there is none after the last note, so the dynamic is skipped.
- **Kern rewrites a held note's rhythm.** A dotted-quarter C with a *p* at its midpoint is written as `[8c` / `4c]`, so it reads back as an eighth tied to a quarter. Kern's null token `.` says "whatever was sounding continues", so the note can stay `4.c`, with a `.` in its column on the row that carries the *p*.
- **Flow JSON merges alias duplicates.** `["mordent", "lower_mordent"]` names one ornament twice and is read as one mordent, while `["mordent", "mordent"]` raises. The writer never produces either.
- **No spec runs a style guideline over a marked flow.** The story's "voice events, continuity, analysis, and style unchanged" criterion is true by construction, but only `voice_events` and `Voice::Continuity` are pinned.
- **The readers list dynamics by hand.** `abc/decoration_mapper.rb` and `lily_pond/mark_reader.rb` spell out the levels and accents that `Dynamic.levels` and `Dynamic.accents` already hold.

## Acceptance Criteria

### MusicXML

- [ ] A voice dynamic after the voice's last event in a bar is written as a `<direction>` after that bar's final note, at the dynamic's position, in both a single-staff part and a grand-staff part
- [ ] A dynamic under a note or rest writes as it does today

### Kern

- [ ] A part dynamic that falls while a note is held writes the note whole, with a null token in its `**kern` column on the dynamic's row
- [ ] Reading that file back gives the note's written rhythmic value, such as a dotted quarter rather than an eighth tied to a quarter, and the dynamic at its position
- [ ] The same holds under a rest, and when several voices in the part hold notes across the dynamic
- [ ] A dynamic that coincides with an attack writes as it does today

### Flow JSON

- [ ] Articulations or ornaments that name one marking twice through different aliases, such as `["mordent", "lower_mordent"]`, raise the same error, with the same path, as a repeated key

### Style

- [ ] A style guideline graded over a flow with articulations, ornaments, and dynamics gives the same marks as over the same flow without them

### Duplication

- [ ] The ABC and LilyPond readers take their dynamic levels and accents from `Dynamic.levels` and `Dynamic.accents`, and read every level and accent they read today

## Notes

- The level placement that wraps `ArgumentError` in `abc/voice_state.rb` and `lily_pond/event_placer.rb` stays duplicated. It is three lines in each, and each reader raises its own kind of error with different location details.
- Dynamics in the middle of a note stay in the model. A dynamic under a held note is ordinary, as in a piano's left hand holding while the right hand gets a new level, and every format can write one without touching the note: kern's null token, MusicXML's `<offset>`, and LilyPond's spacer rests.
- Removing the kern split may change output that specs pin today. Those specs describe the old behavior and change with it.
- A dynamic after a voice's last event in an incomplete bar is written, not refused, because MusicXML can place a direction there without inventing a rest.

## Implementation Plan

[to be filled in by /stories plan]
