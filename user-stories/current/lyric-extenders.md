<!--
metadata:
  created_at:   2026-09-27T15:48:57-07:00
  activated_at: 2026-10-23T21:10:12-07:00
  planned_at:   2026-10-27T21:07:19-07:00
  finished_at:
  updated_at:   2026-10-28T09:26:41-07:00
-->

# Story: Lyric Extenders

## Summary

AS a developer or researcher using HeadMusic

I WANT a syllable sung over several notes to keep its extender

SO THAT melismas survive import and can be written back

Split from [Spans Across Notes](../done/spans-across-notes.md).

## Background

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Lyric extender (melisma) | `_` in `w:` | `__` | `<extend>` | a trailing `_` on a `**text` syllable | `@con="u"` |

- kern's `LyricReader` skips a lone `_` or `|` and keeps a trailing `_` as text (`"Lord_"`), so a melisma reads as notes with no syllable.
- In kern, as Verovio reads it, `Lord_` starts a line and the held notes are null `.` tokens; `|` is a placeholder in `**silbe`. Like MEI, kern marks only where a line starts.
- A `Syllable` holds `text`, `verse`, and `hyphen_after`, and nothing about extension.

## Acceptance Criteria

- [x] Each held note of a melisma carries an extend marker in its verse's slot, in place of a syllable, and the melisma ends on the last marked note
- [x] The voice event just before a marker has a syllable or a marker in that verse, and a marker cannot sit on a rest
- [x] Markers may follow a hyphenated syllable; the syllable's `hyphen_after` decides whether a hyphen or a line is drawn
- [x] Code that reads sung words (MIDI lyric events, the MIDI and notation preflight checks, MusicXML `<syllabic>`) never takes a marker for text
- [x] Flow JSON writes a marker as `{"extend": true}` in `syllables`, adding `"verse"` when it is not 1 as a syllable does, and reading checks each marker against the voice event before it
- [x] MusicXML writes `<extend>` with the melisma's end marked, except after a hyphenated syllable, and reads it
- [x] kern writes `Lord_` on a word-final syllable whose melisma continues and `.` on its held notes; it reads a trailing `_` as a line start, and a lone `_` or `|` as a held note
- [x] MEI writes and reads `@con="u"`, and writes `"d"` on a hyphenated melisma, since `@con` holds one value
- [x] A reader whose format marks only where a line starts (MEI `@con="u"`, kern `Lord_`, a bare MusicXML `<extend/>`), and every reader after a hyphenated syllable, marks each following note with nothing in that verse, passing through notes already held, and stops at the next sung note or rest; a MusicXML word whose `continue` or `stop` marks follow ends where they say
- [x] Round trips assert where each melisma ends, where the format can say so; a melisma that stops before an unsung note is a named exclusion in MEI and kern

## Notes

- ABC `w:` and LilyPond `__` extenders wait for new stories that give those formats lyrics; neither format reads lyrics yet (`w:` and `\new Lyrics` raise).
- The gem does not infer melismas from slurs; it keeps what the file says. The implied-end rule is no exception: the file says a line starts, and the rule only places its end.

### Decisions

- **Mark the held notes, not the end.** A stored end position could point past the next syllable or onto a rest; a marker on each held note can only be checked against its neighbors, gets its verse from its slot, and matches MusicXML's `<extend type="continue">`.
- **An explicit marker, not `"_"` as text.** Text formats and notation programs enter an extender as `_`, but MusicXML and MEI use structure, and a magic string would reach every consumer of syllable text unfiltered.
- **One marker for lines and hyphens.** The syllable that opens the melisma already says which is drawn, so a separate `-` marker would only repeat it.

## Implementation Plan

### Overview

A note event marks the verses it holds over from the syllable before it, in a store beside `syllables`, so nothing that reads sung text can see a marker. Flow JSON writes the markers into `syllables`; writers ask whether the next note holds the verse; and one shared helper, `Notation::MelismaFill`, applies the implied-end rule for every reader whose format marks only a line's start. This follows the pattern of the spans work: model and JSON first, a pause to check the API, then one format per step. Each step is one commit with its CHANGELOG line under Unreleased/Added, and runs the touched specs, `bundle exec rake`, and `bundle exec rubocop -a` first.

### What kern does

Verovio's Humdrum importer (`iohumdrum.cpp`) reads a trailing `_` on a syllable (`sic_`) as the line's start (`@con="u"`), and leaves the held notes as null `.` tokens. `|` is a placeholder in `**silbe`, read like a null. So kern, like MEI, marks only where a line starts. Today's reader keeps that `_` as text (`"sic_"`), which is a bug this story fixes.

### Steps

1. **Model: extend markers on note events**
   - `NoteEvent#extend_syllable(verse: 1)` marks the note as holding that verse and returns self. It raises `ArgumentError` when the note already sings that verse, or when the voice event just before it (ending where this one starts) has neither a syllable nor a marker in that verse.
   - `NoteEvent#sing` raises for a verse the note already holds.
   - `VoiceEvent#extends_syllable?(verse = 1)` and `#extended_verses` (sorted) answer false and `[]` on the base class. `RestEvent#extend_syllable` raises, as `#articulate` does.
   - `VoiceEvent#melisma_continues_after?(verse)` asks whether the next adjacent voice event holds the verse; every writer uses it.
   - `NoteEvent#merge` leaves markers untouched, as it does syllables.
   - Rewrite the comments in `syllable.rb` and `note_event.rb` that say a melisma is the absence of a syllable.
   - Files: `lib/head_music/content/note_event.rb`, `voice_event.rb`, `rest_event.rb`, `syllable.rb`.
   - Specs: `spec/head_music/content/note_event_spec.rb`, `rest_event_spec.rb`.

2. **Flow JSON**
   - `VoiceEvent#markings_to_h` writes markers into `"syllables"`, ordered by verse with the syllables, as `{"extend": true}`, adding `"verse"` when it is not 1, as a syllable does.
   - `VoiceEventValues#voice_event_syllables` accepts a marker entry: `"extend"` must be `true`, and a marker carries no `"text"` or `"hyphen_after"`. A marker and a syllable may not share a verse.
   - `Deserializer` sings syllables as it places each event, then applies a voice's markers after all its events, in position order, so a marker is checked against the event before it whatever order the JSON lists them in. Errors name the path.
   - It stays an optional key within schema 5.
   - Files: `lib/head_music/content/flow/voice_event_values.rb`, `deserializer.rb`, `lib/head_music/content/voice_event.rb`.
   - Specs: the Flow JSON specs beside the existing syllable ones, including markers listed before their syllable and a marker after a rest or a gap.

3. **Fixtures and the round-trip helper**
   - Add `spec/support/melisma_fixtures.rb`: a word-final melisma ending before the next syllable; one ending on a rest; a hyphenated melisma ("glo-" … "-ri-"); two verses with melismas in different places; a melisma through a note tied across a barline; and a melisma that ends before an unsung note (it does not follow the implied-end rule).
   - Add `melisma_ends(flow)`, giving `[voice index, verse, syllable position, last held position]`, and `expect_same_melismas(original, round_tripped)`.
   - The round-trip helpers already compare `syllables` through `to_h`, so markers are compared in every format with no further change.

4. **Pause** to check the API with you before the formats build on it.

5. **`HeadMusic::Notation::MelismaFill`**
   - `fill(note_event, verse)` marks each following adjacent note event that has nothing in that verse, stopping at a sung note, a rest, or a gap.
   - It is applied after a line-start mark (`sic_`, `@con="u"`, a bare `<extend/>`) and after a hyphenated syllable, whose held notes can only be its own (see Story gaps).
   - Files: `lib/head_music/notation/melisma_fill.rb`, next to `span_ends.rb`.
   - Specs: `spec/head_music/notation/melisma_fill_spec.rb`.

6. **MusicXML: write and read `<extend>`**
   - The writer puts `<extend type="start"/>` in the syllable's `<lyric>` when `melisma_continues_after?`. Each held note gets a `<lyric number="n">` holding only `<extend type="continue"/>`, or `type="stop"` on the last one. It writes them on the lead note of a chord and on the first link of a tie, as for syllables. It writes no `<extend>` after a hyphenated syllable.
   - The reader stops dropping `<extend>`. A `continue` or `stop` lyric marks its note in that lyric's verse. A bare or `start` `<extend/>` with no `continue` or `stop` after it falls back to `MelismaFill`. An extend-only lyric takes part in verse ranking. On a rest, a grace note, or a tie's later link it is skipped, as syllables are.
   - Files: `lib/head_music/notation/music_xml/lyric_writer.rb`, `lyric_reader.rb`.
   - Specs: `writer_spec`/`lyric_writer_spec`, `lyric_reader_spec`, `music_xml_round_trip_spec.rb` over the melisma fixtures with `expect_same_melismas`; under the `musicxml_xsd` oracle, an extend-only `<lyric>` validates.

7. **MEI: write and read `@con="u"`**
   - The writer sets `con="u"` on a word-final syllable whose melisma continues, and keeps `"d"` on a hyphenated one. Held notes get no `<verse>`.
   - The reader takes `con="u"` and a hyphen (`@con="d"` or `@wordpos` `i`/`m`) through `MelismaFill`. The "other `@con` values set nothing" comment changes to name `u`.
   - Files: `lib/head_music/notation/mei/lyric_writer.rb`, `lyric_reader.rb`.
   - Specs: the lyric writer and reader specs, and `mei_round_trip_spec.rb` with the melisma fixtures. The fixture that ends before an unsung note is a named exclusion, pinned to read back as filled up to the next sung note or rest. The `mei_schema` oracle checks the output.

8. **kern: write and read extenders**
   - The writer appends `_` to a word-final syllable whose melisma continues (`Lord_`), and writes `.` on held notes, as today. A hyphenated syllable keeps its `-`.
   - The reader strips a trailing `_` from a syllable and fills from it; a hyphenated syllable fills too. A lone `_` or `|` marks its note explicitly in its verse, where the note before it holds the verse; otherwise it is skipped, as today.
   - Files: `lib/head_music/notation/kern/data_rows.rb`, `lyric_reader.rb`, `layer.rb` (which sings syllables onto note events, and now applies markers after them).
   - Specs: `lyric_reader_spec.rb`, `writer_spec.rb`, and `kern_round_trip_spec.rb` with the melisma fixtures; the same named exclusion as MEI. Under the `verovio` oracle, Verovio's MEI from our kern has `con="u"` on the syllable.

9. **Consumers pinned**
   - Specs show that MIDI `LyricEvents`, `MIDI::Preflight#check_texts`, `PreflightChecks#flow_texts`, and MusicXML `<syllabic>` ignore markers: a melisma writes one MIDI lyric event, and the syllable after a melisma still gets `begin`, `middle`, or `end` from the one before it.
   - Update `MuseScoreFixtures.two_verses`, whose "zing" is held over the eighth after it, if its MusicXML or MEI comes back with markers. That is a melisma in the hymn, but the fixture states none.

### Data model changes

- `NoteEvent` gains extend markers per verse; `VoiceEvent` gains `#extends_syllable?`, `#extended_verses`, and `#melisma_continues_after?`.
- Flow JSON `syllables` entries may be `{"extend": true, "verse": n}`, within schema 5.

### Risks and open questions

- **Gaps in a voice.** A marker needs the event just before it to end where it starts, so a note placed later into a gap can never sit between a marker and its syllable.
- **Hyphenated melismas in existing fixtures.** Once readers fill after a hyphen, any fixture with a hyphenated syllable followed by unsung notes reads back with markers its source lacks. Those sources should state the markers, since such notes can only be held.
- **MusicXML from other programs.** MuseScore and Finale may write only a bare `<extend/>`, or put `<extend>` after a hyphenated syllable. The reader handles both, but the `musicxml_corpus` oracle is the check.
- **Verovio's CLI** isn't installed. The `verovio` oracle is skipped until it is.

### Story gaps adopted

- kern follows Verovio: `Lord_` and null held notes, with lone `_` and `|` read as held notes.
- A hyphenated syllable implies its held notes in every reader, and MusicXML writes no `<extend>` after one.
- A JSON marker omits verse 1, as a syllable does.
- Round trips assert melisma ends only where the format can say them.

## Review

Reviewed on 2026-10-28 at `844ff044`, by an independent agent whose findings were checked against the source.

| # | Criterion | Verdict |
|---|---|---|
| 1 | Held notes carry markers | ✅ `note_event.rb` `extend_syllable`; `voice_event_spec` extenders |
| 2 | The event before a marker sings or holds the verse; no marker on a rest | ✅ `holdable?`, `rest_event.rb`; specs for both |
| 3 | Markers may follow a hyphenated syllable | ✅ `voice_event_spec`; MusicXML `writer_spec` |
| 4 | Consumers never take a marker for text | ✅ After fixes; was ⚠️ until the preflight checks were pinned (`c4068c56`) |
| 5 | Flow JSON `{"extend": true}` | ✅ `flow_serialization_spec`, including markers listed out of order |
| 6 | MusicXML writes and reads `<extend>` | ✅ After fixes; was ⚠️ for finding A |
| 7 | kern `Lord_`, `.`, lone `_` and `\|` | ✅ kern `writer_spec`, `lyric_reader_spec`, round trip |
| 8 | MEI `@con="u"` and `"d"` | ✅ MEI lyric writer and reader specs |
| 9 | Readers fill to the next sung note or rest | ✅ After fixes; was ⚠️ for findings A and C |
| 10 | Round trips assert melisma ends, with a named exclusion | ✅ MusicXML, MEI, and kern round-trip specs |

### Findings

- **A. A bare MusicXML `<extend/>` on a sung syllable holds nothing.** Confirmed in the source.
  - `music_xml/lyric_reader.rb` stores `extend && XmlReading.attribute(extend, "type")`, which is `nil` when there is no `type`, so `fill` returns early.
  - Criterion 9 names this case, and MuseScore and Finale are expected to write it.
  - The spec covers a bare `<extend/>` only on a text-less lyric.
- **B. kern `-_` reads as an empty syllable `""`.** Confirmed in the source.
  - `kern/lyric_reader.rb` checks `HELD` against the raw field, but checks for the trailing `_` after stripping the leading `-`.
  - An empty syllable then reaches MIDI and the preflight checks. Before this branch it read as `"_"`.
- **C. A fill stops early at an explicit marker.** For example, kern `Lord_ / _ / . / praise` leaves the third note unheld.
  - It needs mixed input, and an explicit mark arguably wins.
  - Either fill through, or reword criterion 9 to say a fill stops at a held note.
- **D. A JSON extender error names `…syllables`, not the entry.** `deserializer.rb:116` passes `"#{path}.syllables"`, while shape errors name `syllables[i]`. Low severity.
- **E. Two broad rescues.** `MusicXML::LyricReader#hold` and `Kern::Layer#hold` rescue every `ArgumentError`. Today they can only skip the two expected refusals. Low severity.
- **F. Comment density.** About 40 new comment lines in lib, more than the minimal-comments convention suggests.

### Resolutions

Each finding was reproduced with a failing spec before it was fixed.

- **A.** Fixed in `5c82ff4e`: an `<extend>` with no `type` attribute now counts as an extend.
- **B.** Fixed in `4dbf0d45`: the reader checks for a held mark after stripping the leading hyphen.
- **C.** Fixed in `35372112`: a fill passes through notes already held. A MusicXML word whose `continue` or `stop` marks follow ends where they say, and a hyphenated syllable still fills past them. Criterion 9 now says so.
- **D.** Fixed in `776cf610`: each extender carries its entry's path.
- **Criterion 4.** Pinned in `c4068c56`.
- **E and F.** Left as they are.
