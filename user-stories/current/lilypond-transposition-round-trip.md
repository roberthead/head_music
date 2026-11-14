<!--
metadata:
  created_at:   2026-11-12T22:35:12-05:00
  activated_at: 2026-11-13T09:54:36-05:00
  planned_at:   2026-11-13T10:03:14-05:00
  finished_at:
  updated_at:   2026-11-13T20:18:30-05:00
-->

# Story: LilyPond Transposition Round Trip

## Summary

AS a developer writing a transposed LilyPond score with head_music
I WANT the reader to read what the writer wrote
SO THAT a part for a transposing instrument comes back at the right pitch instead of raising

## Acceptance Criteria

- A flow with a transposing part, realized at written pitch and rendered with
  `transposed: true`, parses back without raising, and its pitches read back
  at concert pitch.
- `\transposition` in a file from elsewhere is read, not refused, wherever
  LilyPond allows it (at the start of a staff or voice, and mid-voice).
- A spec renders every transposing catalog instrument with `transposed: true`
  and reads it back.
- A part that changes instrument mid-flow (for example clarinet in B♭ to
  clarinet in A to flute) round-trips at concert pitch: the writer restates
  `\transposition` where the transposition changes, including
  `\transposition c'` back to concert.
- A part of several voices on one staff reads back as one part, not one part
  per voice, and each voice keeps its own role.
- Such a part reads its instrument from the staff's `instrumentName` when the
  catalog knows the name, with the opening `\transposition` choosing among
  the instrument's key variants (a staff named "Clarinet" holding
  `\transposition a` reads as clarinet in A).

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
- Side finding, folded into this story: a two-voice part written as one
  `\new Staff \with { instrumentName = "…" }` reads back as two parts (cause
  under Confirmed, below).
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
  Unrelated to transposition. The writer also drops the roles: a single-staff
  part of several voices writes each as an unnamed `\new Voice`
  (`Writer#single_staff_lines`), though grouped staves already name each
  voice for its role.

### Approach

Read `\transposition` as the written-to-sounding step in force on a voice
stream, and convert each pitch and key to concert pitch as the stream
collects it, reusing `HeadMusic::Notation::ConcertTransposition` (the MusicXML
and MEI readers' helper). Have the writer restate `\transposition` wherever a
part's instrument changes its transposition. Separately, read the voices of
one ungrouped staff as one part, and name each voice for its role on the way
out, as grouped staves already do.

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
6. **Name voices on a shared staff.** In `Writer#single_staff_lines`, write
   each voice of a several-voice staff as `\new Voice = "<role>"` when it has
   a role, as `grouped_staff_lines` does. The staff keeps
   `instrumentName` for the part.
7. **Remember the staff.** Give `Document` an ungrouped-staff record
   (`Document::Staff`, holding its `instrumentName`), and have
   `ContextReader#read_staff_or_voice` tag each stream read inside a `\new
   Staff` outside a group with it. A Voice's own context name is kept on the
   stream apart from the staff's name.
8. **One part per staff.** In `PartLayout#ungrouped_voice`, the first stream
   of a staff makes the part (`flow.add_voice`), and later streams of the same
   staff join it (`part.add_voice`). Role: a staff's only voice takes the
   staff's `instrumentName` as today (`document_reader_spec` pins
   `[["Melody", 1]]`); among several, each voice takes its own context name, or
   none, since the staff's name then names the part. `dynamics_parts` returns
   each part once, so a `\new Dynamics` beside a two-voice staff places its
   dynamics once.
9. **Name the instrument.** Move `MusicXML::InstrumentNames` to
   `HeadMusic::Notation::InstrumentNames` (`lib/head_music/notation/`), since
   two readers now share it, and have `PartLayout` give a several-voice
   staff's part the instrument its `instrumentName` names. A single-voice
   staff keeps the name as its voice's role and gets no instrument, as today.
   A name the catalog doesn't know is dropped.
10. **Pick the variant.** Move the MusicXML `IdentityReader`'s variant pick
    (instrument whose `sounding_transposition` matches, among the
    `parent_key` siblings) to where both readers can call it, and apply it
    with the semitones of the staff's opening `\transposition` (the first
    one, in the first voice, before any music). Later `\transposition`s move
    pitches only; they make no instrument change, since LilyPond doesn't say
    which instrument the part changed to.
11. Update the comment in `MusicReader` that names `\transpose` as the
    unsupported example, if the wording now misleads, and add CHANGELOG
    entries under Unreleased: Fixed (the reader reads `\transposition`; the
    writer restates it at instrument changes), Changed (a several-voice
    staff's name sets its part's instrument), and **Breaking.** (several
    voices on one staff read back as one part, with their own roles, where
    they used to read as a part each).

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
- Several voices on one staff: a violin part with voices "upper" and
  unnamed, and a two-voice clarinet in A rendered transposed, each read back as
  one part with the original roles. The reader specs cover a named staff whose
  voices are named, unnamed, and mixed, and a `\new Dynamics` beside it
  placing each dynamic once.
- Instrument from the staff name: "Clarinet in A" and "A Clarinet" on a
  two-voice staff give clarinet in A; "Clarinet" with `\transposition a`
  gives clarinet in A, and with no `\transposition` the catalog's clarinet;
  an unknown name gives no instrument; a single-voice staff gives none and
  keeps the role. The MusicXML instrument specs keep passing after the move.
- LilyPond MIDI oracle (skips when `lilypond` is not installed, like the
  writer's compile specs): compile the rendered transposed documents with a
  `\midi` block, read the MIDI with `HeadMusic::MIDI.parse`, and compare MIDI
  note numbers with the concert flow's. Spelling is compared only by our own
  round trip, since MIDI spells by key.

### Risks and open questions

- A written key whose concert key needs double sharps or flats (rare, such
  as written C♭ major for a B♭ instrument) raises from `KeySignature`; it
  should surface as `UnsupportedFeatureError` with the line.
- LilyPond carries no machine identity, so an instrument comes back only from
  a several-voice staff's name the catalog knows, and never an instrument
  change. A single-voice part comes back with no instrument.
- A `\markup` instrument name, such as `\markup { "Clarinet in B" \flat }`,
  reads as its plain words ("Clarinet in B") and names no instrument.
- Reading a several-voice staff as one part changes what existing documents
  parse to: `\new Staff \with { instrumentName = "Melody" } << \new Voice …
  \new Voice … >>` used to give two parts with role "Melody" each, and will
  give one part whose voices have no role. Specs pinning the old shape
  (`lily_pond_dynamics_spec`, `flow_builder_spec`, round-trip dynamics cases)
  will need updating, and the CHANGELOG entry should say so.
- `\transposition` in a `\with` block is not LilyPond syntax (it would be
  `instrumentTransposition = #(ly:make-pitch …)`), so it is left to
  `AssignmentReader`'s existing error.

## Review

Reviewed 2026-11-13 at `87e857a6` by an independent agent; each finding below was
reproduced before it was recorded here.

| Criterion | Verdict | Evidence |
|---|---|---|
| Transposed written flow parses back at concert pitch | ✅ | `setting_reader.rb` `read_transposition`, `voice_stream.rb` `change_transposition`; `lily_pond_transposition_spec.rb` round trip |
| `\transposition` read wherever LilyPond allows it | ⚠️ | Voice start, mid-voice, `\relative`, tuplets, staff to voice, `\new Dynamics` all read; not staff-wide across voices (1), not inside `\grace { }` or mid-tie (3) |
| Every transposing catalog instrument round-trips | ✅ | `lily_pond_transposition_spec.rb`, one example per instrument, plus the LilyPond MIDI check |
| A part changing instrument round-trips, `\transposition` restated | ✅ | `render_plan.rb` `transposition_changes`, `voice_writer.rb` `change_commands`; silent staves excepted (4) |
| Several voices on one staff read as one part, with roles | ✅ | `part_layout.rb` `ungrouped_voice`, `writer.rb` `single_staff_lines`; `lily_pond_shared_staff_spec.rb` |
| Instrument from a several-voice staff's name, variant by opening `\transposition` | ✅ | `part_layout.rb` `staff_instrument`, `instrument_names.rb` `variant`; misses a `\transposition` in a later voice (1) |

### Findings

1. **Medium.** `\transposition` in one voice of a shared staff doesn't reach
   the staff's other voices, though in LilyPond it is a Staff property.
   `\new Staff << \new Voice = "a" { \transposition bes d''1 } \new Voice = "b" { e''1 } >>`
   reads C5 and E5; LilyPond's MIDI plays C5 and D5. The variant pick reads
   only the first voice's opening transposition, so it misses one in a later
   voice. The gem's own writer restates it in every voice, so its round trip is
   unaffected.
2. **Low.** A concert key past seven sharps or flats is read silently, not
   refused as planned: `{ \transposition bes \key ces \major ces''1 }` reads as
   B𝄫 major (9 flats), which the writer then renders. Untested.
3. **Low.** Valid LilyPond refused: `{ \grace { \transposition bes d''8 } c''1 }`
   raises `UnsupportedFeatureError` (the grace reader doesn't route settings),
   and `{ \transposition bes c''2~ \transposition c' c''2 }` raises "A tie must
   connect two notes of the same pitch", since the tie now compares concert
   pitches.
4. **Low.** A silent staff (`VoiceWriter#silent_lines`) writes no
   `\transposition` at an instrument change, nor a key change, which predates
   this story. No pitches are lost.
5. **Low, by design.** On a several-voice staff a name the catalog doesn't
   know survives nowhere: `instrumentName = "Melody"` with two voices reads as
   one part, no instrument, roles `[nil, nil]`. This is the CHANGELOG's
   **Breaking.** entry.
6. **Low.** Key resettling reaches back across spacers, since `Event#music?`
   doesn't count them: `{ \key f \major s1 \transposition a f''1 }` reads the
   bar-one key as D major. The writer never produces this.
7. **Nits.** `Writer#part_name`'s comment now describes voice naming, which
   happens in `single_staff_lines`; `PartLayout`'s header comment reads
   awkwardly.

Nothing blocks `finish` against the criteria as written, but 1 and 3 leave
criterion 2 partial for files from elsewhere.

### Resolution

Findings 1, 2, 3, 6, and 7 were fixed in `715f2ff6`, which brings criterion 2
to ✅. Each new reading of 1 and 3 was checked against LilyPond 2.26's MIDI.
Finding 4 was fixed in the commit after, with the key changes silent staves
were missing; the rendered score compiles in LilyPond without warnings. Finding 5 was
resolved by reading a several-voice staff's `instrumentName` as the part's
player, as MusicXML, MEI, and kern read a part name, so "Melody" is kept and
written back; one part per staff remains the **Breaking.** change.
