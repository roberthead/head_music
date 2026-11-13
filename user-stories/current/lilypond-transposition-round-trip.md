<!--
metadata:
  created_at:   2026-11-12T22:35:12-05:00
  activated_at: 2026-11-13T09:54:36-05:00
  planned_at:   2026-11-13T10:03:14-05:00
  finished_at:
  updated_at:   2026-11-13T10:03:14-05:00
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

### Confirmed (2026-11-13)

- All 50 transposing catalog instruments raise `UnsupportedFeatureError:
  Unsupported LilyPond feature "\transposition"` when a written flow is
  rendered with `transposed: true` and parsed. The command reaches
  `VoiceItemReader#read_command`, falls through to
  `MusicReader#read_expression_command`, and is refused there.
- `transposed: true` expects a flow a layout has realized at written pitch
  (`Layout#realize` with `concert_pitch: false`), as the MusicXML round trip's
  `written(flow)` helper does. The writer then writes the notes as given,
  derives each part's written key, and adds `\transposition`. Rendering a
  concert flow with `transposed: true` writes a written key over concert notes
  by design, not by bug.
- The writer emits `\transposition` only at a voice's opening
  (`VoiceWriter#opening_lines`). At an instrument change it writes the new
  written key (`RenderPlan#instrument_change_keys`) and written pitches, but no
  new `\transposition`. Clarinet in B♭ changing to clarinet in A, or to flute,
  would read back wrong from bar 2 even once the reader honors the command.
- LilyPond 2.26's MIDI output confirms the semantics: under `\transposition
  bes` a written c'' sounds B♭4, a later `\transposition c'` resets to concert,
  and the argument is absolute even inside `\relative` (it neither takes nor
  moves the relative reference).
- Side finding, cause traced: `PartLayout#ungrouped_voice` reads every stream
  outside a staff group as a part of its own, while the writer puts a
  multi-voice part on one `\new Staff << \new Voice … \new Voice … >>`. Any
  two-voice part splits (violin too, not only transposing parts), and each
  voice takes the staff's `instrumentName` as its role, losing its own.
  Unrelated to transposition.

### Approach

Read `\transposition` as the written-to-sounding step in force on a voice
stream, and convert each pitch and key to concert pitch as the stream
collects it, reusing `HeadMusic::Notation::ConcertTransposition` (the MusicXML
and MEI readers' helper). Have the writer restate `\transposition` wherever a
part's instrument changes its transposition.

### Steps

1. **Read the command.** Add `TranspositionReader` (or a `transposition`
   branch in `SettingReader`, alongside `\key`) in
   `lib/head_music/notation/lily_pond/`: consume `\transposition`, then one
   bare note token read with `PitchReader.absolute` (never the relative
   stack), and raise `ParseError "\transposition expects a pitch"` otherwise.
   Build a `ConcertTransposition::Step` from the pitch's distance to c'
   (semitones and diatonic steps, split into octaves and a within-octave
   remainder, as the MusicXML `<transpose>` reader does).
2. **Hold it on the stream.** `VoiceStream#change_transposition(step)` keeps
   a `ConcertTransposition` (`errors: HeadMusic::Notation::LilyPond`). Notes,
   chord members, and graces convert to concert in `add_note` and
   `add_graces`, so ties compare concert pitches on both sides. A key converts
   by its fifths (`concert_fifths`), keeping its mode. `\transposition` also
   re-converts the key events after the stream's last music event, so a
   `\key` written before `\transposition` on the same downbeat reads like one
   written after it (the lesson from the MusicXML key/transpose order fix).
3. **Inherit it.** In `ContextReader#read_staff_or_voice`, a child stream
   starts with its parent's transposition, as it already inherits
   `numeric_time_signature`, so `\new Staff { \transposition bes \new Voice
   { … } }` applies to the voice.
4. **Accept it wherever LilyPond does.** Route `\transposition` from
   `VoiceItemReader#read_command` to step 1. In `DynamicsItemReader`, read it
   for its syntax alone, as `SettingReader` does with no stream.
5. **Write it at instrument changes.** Add
   `RenderPlan#transposition_changes(part)` in
   `lib/head_music/notation/lily_pond/render_plan.rb`: for each
   `part.instrument_changes` bar after the first, the sounding pitch of a
   written c' when it differs from the bar before (so B♭ clarinet to B♭ bass
   clarinet writes one, and B♭ clarinet to B♭ trumpet does not). Use
   `\transposition c'` when the new instrument is in C. In
   `VoiceWriter#change_commands`, write it before the bar's `\key`. Empty
   unless `plan.transposed?`.
6. Update the comment in `MusicReader` that names `\transpose` as the
   unsupported example, if the wording now misleads, and add CHANGELOG
   entries under Unreleased (Fixed: the reader reads `\transposition`; the
   writer restates it at instrument changes).

### Data model changes

None. `VoiceStream` gains a transposition, which is reader state.

### Tests

- `spec/head_music/notation/lily_pond/` reader specs: notes after
  `\transposition bes` read a major second lower; `\key f \major` reads as
  D major after `\transposition a`, in either order before the first note;
  `\relative` is unaffected by the argument; chords and graces convert; a
  mid-voice `\transposition c'` resets; a staff-level `\transposition` reaches
  its voice; one inside `\new Dynamics` is accepted; a missing pitch raises
  `ParseError`.
- A flute in D major and a clarinet in A in one score read back without a
  "Conflicting \key" error, both in D major.
- Writer spec: an instrument change writes `\transposition` (and `c'` back to
  concert), an unchanged transposition writes none, and `transposed: false`
  writes none.
- Round trip (`spec/head_music/notation/lily_pond_round_trip_spec.rb`, new
  "transposed" group): every `Instrument.all.select(&:transposing?)`, as a
  written flow rendered with `transposed: true`, reads back with the concert
  flow's pitches and key. Also a part that changes from clarinet to clarinet in
  A to flute.
- LilyPond MIDI oracle (skips when `lilypond` is not installed, like the
  writer's compile specs): compile the rendered transposed documents with a
  `\midi` block, read the MIDI with `HeadMusic::MIDI.parse`, and compare MIDI
  note numbers with the concert flow's. Spelling is compared only by our own
  round trip, since MIDI spells by key.

### Risks and open questions

- A written key whose concert key needs double sharps or flats (rare, such
  as written C♭ major for a B♭ instrument) raises from `KeySignature`; it
  should surface as `UnsupportedFeatureError` with the line.
- The reader recovers concert pitch only. LilyPond carries no instrument
  identity, so the reparsed parts have no instrument and no instrument changes.
- `\transposition` in a `\with` block is not LilyPond syntax (it would be
  `instrumentTransposition = #(ly:make-pitch …)`), so it is left to
  `AssignmentReader`'s existing error.
