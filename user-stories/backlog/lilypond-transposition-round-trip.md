<!--
metadata:
  created_at:   2026-11-12T22:35:12-05:00
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-11-12T22:35:12-05:00
-->

# Story: LilyPond Transposition Round Trip

## Summary

AS a developer writing a transposed LilyPond score with head_music
I WANT the reader to read what the writer wrote
SO THAT a part for a transposing instrument comes back at the right pitch instead of raising

## Acceptance Criteria

- A flow with a transposing part, rendered with `transposed: true` and parsed
  back, does not raise, and its pitches read back at concert pitch.
- `\transposition` in a file from elsewhere is read, not refused, wherever
  LilyPond allows it (at the start of a staff or voice, and mid-voice).
- A spec renders every transposing catalog instrument with `transposed: true`
  and reads it back.

## Notes

- Found in the MusicXML instrument fallback story's research (2026-11-12).
- The writer emits `\transposition {pitch}` for a transposing instrument when
  `transposed: true` (`lib/head_music/notation/lily_pond/voice_writer.rb`,
  `transposition_line`). The reader raises `UnsupportedFeatureError:
  Unsupported LilyPond feature "\transposition"`
  (`lib/head_music/notation/lily_pond/token_cursor.rb`,
  `unsupported_command`). All 50 transposing instruments fail.
- No spec renders LilyPond with `transposed: true` and reads it back.
- Readers should skip valid notation the model cannot hold and raise only on
  unrecognized syntax; `\transposition` is valid LilyPond.
- Side finding, cause not traced: a two-voice clarinet_in_a part written as
  one `\new Staff \with { instrumentName = "clarinet in A" }` reads back as
  two parts.
- LilyPond carries no instrument identity, so the reader can't recover the
  instrument, only the pitches. `instrumentName` is read as a voice role.

## Implementation Plan

[to be filled in by /stories plan]
