<!--
metadata:
  created_at:   2026-09-27T11:54:27-07:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-27T11:54:27-07:00
-->

# Story: Place Voice Dynamics Where No Note Starts

## Summary

AS a developer or researcher using HeadMusic

I WANT a voice dynamic under a held note, or after the voice's last note, to keep its position when written as ABC, LilyPond, or kern

SO THAT no writer moves or drops a dynamic without a word

## Background

Found while planning [Markings Review Follow-ups](../current/markings-review-follow-ups.md), which fixed the same gaps in MusicXML and, for dynamics under held notes, kern.

- **LilyPond and ABC move a voice dynamic under a held note to the next note.** A voice *p* at 1:2 under `c3 d` writes `c''2. d''4\p`. The previous story accepted this. LilyPond could write the dynamic as a part dynamic in `\new Dynamics`, changing its owner as kern already does; ABC has no timed spacer that leaves the note untouched.
- **Kern, ABC, and LilyPond drop a voice dynamic after the voice's last note in a bar.** `C D E` in 4/4 with *f* at 1:4 writes no *f*. Kern filters out offsets at or past the bar's written length (`kern/data_rows.rb:31-32`).
- **Every writer drops a dynamic in a bar after the last written bar.**

## Acceptance Criteria

- [ ] Each writer either places such a dynamic at its position or raises a render error naming the position
- [ ] The choice for each format is recorded in the Notes, with the reason

## Notes

[to be decided when planned]

## Implementation Plan

[to be filled in by /stories plan]
