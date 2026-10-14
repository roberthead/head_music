<!--
metadata:
  created_at:   2026-09-27T11:54:27-07:00
  activated_at: 2026-10-13T20:34:36-07:00
  planned_at:   2026-10-13T21:08:28-07:00
  finished_at:
  updated_at:   2026-10-13T21:08:28-07:00
-->

# Story: Place Dynamics Where No Note Starts

## Summary

AS a developer or researcher using HeadMusic

I WANT a voice dynamic under a held note, and a voice or part dynamic after the last note, to keep its position when written as ABC, LilyPond, kern, or MusicXML

SO THAT no writer moves or drops a dynamic without a word: each places it or refuses it

## Background

Found while planning [Markings Review Follow-ups](../done/markings-review-follow-ups.md), which fixed the same gaps in MusicXML and, for dynamics under held notes, kern.

- **LilyPond and ABC move a voice dynamic under a held note to the next note.** A voice *p* at 1:2 under `c3 d` writes `c''2. d''4\p`. The previous story accepted this. LilyPond could write the dynamic as a part dynamic in `\new Dynamics`, changing its owner as kern already does; ABC has no timed spacer that leaves the note untouched. ABC moves a part dynamic the same way, since it writes part levels on its one voice.
- **Kern, ABC, and LilyPond drop a voice dynamic after the voice's last note in a bar.** `C D E` in 4/4 with *f* at 1:4 writes no *f*. Kern filters out offsets at or past the bar's written length (`DataRows#dynamic_offsets`). This happens only after the music ends, in a short final bar: kern writes a dynamic after one voice's last note when another voice continues, and LilyPond refuses voices that end at different times.
- **Kern and LilyPond drop a part dynamic after the flow's last note in a bar the same way.** A part *f* at 1:4 after `C D E` writes nothing and reads back as no dynamic. LilyPond's `RenderPlan#dynamics_bar` keeps only offsets inside the bar.
- **Every writer drops a dynamic in a bar after the last written bar**, including one exactly at the flow's end, and one in a bar before the first written bar. No error is raised: `ensure_markings_within_music` checks bar markings, not dynamics.
- **Kern moves a dynamic before a pickup's first note onto that note.** A part *p* at 0:2 before a pickup C at 0:4 reads back at 0:4.
- **ABC and kern write only one of a voice and a part dynamic at one position.** With a voice *p* and a part *f* at 1:2, ABC writes the *p* and kern the *f*.
- MusicXML has no reader in the gem, so its specs check the written XML.

## Acceptance Criteria

- [ ] Each writer either places such a dynamic at its position or raises a render error naming the position
- [ ] The choice for each format is recorded in the Notes, with the reason
- [ ] Every writer raises a `RenderError` naming the level and position for a voice or part dynamic in a bar before or after the written music, including exactly at the flow's end, before writing anything
- [ ] A voice or part dynamic inside a note or rest reads back at its exact position, with every voice event unchanged, in ABC (overlay of invisible rests), LilyPond (`\after`, voice dynamics staying voice dynamics), and kern (unchanged)
- [ ] A voice or part dynamic after the last note of a short final bar reads back at its exact position in ABC, LilyPond, and kern, with no rest added to any voice; MusicXML writes it after the last note
- [ ] Kern writes a dynamic before a pickup's first note at its position
- [ ] ABC and kern raise a `RenderError` naming the position when a part and its voices hold dynamics at one position
- [ ] ABC raises a `RenderError` naming the position for a dynamic no binary length reaches
- [ ] Every LilyPond output in the new specs compiles under LilyPond 2.26 with no warnings or programming errors
- [ ] Round trips assert each dynamic's owner and exact position, not the level in force at each note
- [ ] CHANGELOG has **Breaking.** entries for the new refusals, for ABC and LilyPond moving off the next note, and for kern import dropping trailing `ryy`

## Notes

- **Rule for every format.** A dynamic is placed at its position wherever its bar is written. A dynamic in a bar before or after the written music, including exactly at the flow's end, raises a `RenderError` naming its level and position, as bar markings past the music already do (`ensure_markings_within_music`). Writing it would add bars the flow does not have, and every format would show them as empty measures.
- **MusicXML places every case within the written bars** with `<direction>` and `<offset>`, which takes no time and leaves notes whole. The gem has no MusicXML reader, so specs check the written offsets.
- **kern** places a dynamic under a held note or rest on null rows (the previous story's work). It places one after the last note of a short final bar, or before a pickup's first note, on invisible rests (`ryy`) or the pickup's written leading rest. The reader drops `ryy` that ends a spine, so the model gains no rest; Verovio puts the dynamic on the exact beat. kern has one `**dynam` spine per part, so a voice dynamic reads back as a part dynamic. It refuses a voice and a part dynamic at one position, because only one can be written.
- **ABC** places a dynamic inside a note or rest on a voice overlay of invisible rests (`& x2 !p!x6`), which leaves the note whole, and one after the last note on a trailing `x`. A tied split (`c2- !p!c4`) was rejected: it reads back as a different rhythmic value, prints a tie the source lacked, and cannot place a dynamic under a rest. ABC writes one voice, so part dynamics read back as voice dynamics. It refuses an offset no binary length reaches, and a voice and a part dynamic at one position. Whether abcm2ps and abcjs draw a dynamic on an overlay's `x` is unverified; no ABC renderer was available.
- **LilyPond** places a voice dynamic inside a note with `\after`, which leaves the note whole and keeps the voice as owner. It places one after the last note on spacer rests in every voice, with a part dynamic in `\new Dynamics`. `\after` is not used at the very end of the music, where LilyPond 2.26 prints "programming error: no broken bound".
- **Invisible time reads the same way in every reader.** An `x`, `s`, or `ryy` that ends a voice adds no event; one followed by music is a rest, since the model has no invisible rest and a gap could not be written back.
- **A short final bar is written full** when a dynamic falls after the music in it. The added time is invisible, and the music reads back ending where it did.
- [Hairpins](../current/hairpins.md) reuses this story's mechanisms for hairpin starts and ends: the shared preflight, `ABC::PositionMarks`, `LilyPond::TimedMarks`, and kern's row grid with `ryy`.

## Implementation Plan

### Overview

Each writer places a voice or part dynamic at its exact position wherever its bar is written, using its own position-keyed mechanism: ABC a voice overlay of invisible rests (`& x2 !p!x6`) inside a note or rest and a trailing `x` after the last note; LilyPond `\after D \p` inside a note and spacers `s` after the last note; kern the existing null-row grid plus `ryy` invisible rests; MusicXML `<offset>`, which already works. First, every writer raises a `RenderError` naming the position for a dynamic outside the written bars, through one shared preflight check. Each reader learns its new form before its writer emits it, so no commit writes files that read back wrong.

Oracles: LilyPond 2.26 (grep stderr for `warning|error|programming error`; exit 0 hides them), and Verovio 6.3.0 for kern (checked by hand, not in the suite). No ABC renderer is installed.

### Steps

Each step is one commit. Run the touched specs, then `bundle exec rake` and `bundle exec rubocop -a`.

1. **Refuse a dynamic outside the written bars, in every writer.** Add `ensure_dynamics_within_music(flow)` to `notation/preflight_checks.rb`, called after `ensure_markings_within_music` in `abc/writer.rb`, `kern/preflight.rb`, `lily_pond/preflight.rb`, and `music_xml/preflight.rb`. Range: `flow.earliest_bar_number..flow.last_sounding_bar_number`, over `flow.parts` and `flow.voices` dynamics sorted by position. Messages: `the dynamic f at 3:1:000 falls after the music ends in bar 1`, `the dynamic p at 0:2:000 falls before the music starts in bar 1`. Build it over `[label, position]` pairs so hairpin marks can join later. Specs: a four-format table (voice *f* at 3:1, part *f* at 3:1, voice *f* at the flow's end, part *p* at 0:2), plus "still writes" cases (a bar reached only by a tie, a pickup dynamic under a written rest). Rewrite the specs that pin the drop (`abc/writer_spec.rb`, `kern/writer_spec.rb`, `lily_pond/writer_spec.rb`). CHANGELOG (Changed, **Breaking.**).
2. **Refuse two dynamics that one written line cannot both hold (ABC, kern).** Raise naming both and the position, in `kern/preflight.rb` and `abc/writer.rb#validate!`. CHANGELOG (Changed, **Breaking.**).
3. **Pin MusicXML placement (specs only).** XPath assertions in `music_xml/writer_spec.rb` for the exact `<offset>` and order: voice *p* at 1:2 under a dotted half; trailing voice *f* after `C D E`; part *f* at 1:4; part *p* under a held note; voice *p* at 2:2 in a bar reached by a tie; a pickup with a leading rest.
4. **Kern reader: an invisible rest that ends a spine adds no event.** `kern/token_reader.rb` flags `yy` rests (`4ry` stays visible); `kern/voice_cursor.rb`, `kern/layer.rb`, `spine_voices.rb` leave out invisible rests after the last visible event. A mid-voice `ryy` stays a `RestEvent`. Run the `KERN_CORPUS` sweep. CHANGELOG (Changed, **Breaking.**).
5. **Kern writer: write a dynamic after the music's end in the final bar on `ryy`.** `kern/written_bars.rb` writes the final bar full when a dynamic follows the music in it; `kern/spine_tokens.rb` writes that fill as `ryy` in every spine; remove the `offset < length` filter in `kern/data_rows.rb`. Round-trip specs assert exact positions, voice values, and `latest_bar_number`. CHANGELOG (Fixed).
6. **Kern writer: keep a pickup dynamic before the pickup's first note.** Write the pickup's leading rest when a dynamic precedes the first note, and let the null-row grid place it; remove the clamp in `kern/dynamic_fields.rb` and adjust `pickup_start` in `kern/written_bars.rb`. CHANGELOG (Fixed).
7. **ABC reader: read `x` and `y`.** Scan both in `abc/line_scanner.rb` (`x` leaves `UNSUPPORTED_PATTERNS`, and `y` stops raising `ParseError`); a time cursor in `abc/voice_state.rb` may run ahead of `voice.next_position`; `abc/pending_decorations.rb` places a level on `x` or `y` at the cursor and drops other decorations there; `Decoration#positional?`. An `x` that ends the voice adds no event; one followed by music is a `RestEvent`. CHANGELOG (Added).
8. **ABC reader: read a voice overlay `&` of invisible rests.** `&` resets the cursor to the bar's start; inside it only `x`, `y`, and decorations are read; time returns at the barline. An overlay holding notes or rests raises `UnsupportedFeatureError`, because reading it means a second voice. CHANGELOG (Added).
9. **ABC writer: place every dynamic at its position.** New `abc/position_marks.rb` (`ABC::PositionMarks`) for the voice's and part's dynamics; each mark goes on the note or rest attacking there, in one overlay per bar filled to the written length, or on a trailing `x` after the music's end in the final bar. `abc/decoration_writer.rb` stops using `DynamicPlacement`. `validate!` raises naming the position when no binary length reaches an offset. Round trips assert `[owner, position, level]` and that voice events compare equal by `to_s`. CHANGELOG (Changed, **Breaking.**).
10. **LilyPond reader: read a spacer `s` in a voice.** `lily_pond/music_reader.rb`, `event_placer.rb` (per-voice cursor), `flow_builder.rb`; share the fraction-to-position helper from `PartDynamics#after_spacer`. A spacer ending the voice adds no event; one followed by music is a `RestEvent`. CHANGELOG (Added).
11. **LilyPond reader: read `\after D mark music`.** A lexer `:after` token with a dotted or multiplied duration; `music_item_reader.rb#read_after` leaves the default duration alone; nesting through `voice_stream.rb`'s `InnerEvent` path; `event_placer.rb` places levels at position plus offset. Non-level marks under `\after` are dropped. CHANGELOG (Added).
12. **LilyPond writer: write a voice dynamic inside a note with `\after`.** New `lily_pond/timed_marks.rb` (`LilyPond::TimedMarks`) answers, for each mark, the attacking link, `\after D` on the containing link, or a trailing spacer. Replace `DynamicPlacement` in `lily_pond/render_plan.rb`, and delete `notation/dynamic_placement.rb` and its spec. Add `compile_warnings` to `spec/support/lily_pond_helpers.rb` (Open3, `-l WARNING`). CHANGELOG (Changed, **Breaking.**).
13. **LilyPond writer: write dynamics after the music's end in a short final bar.** Every voice gets `s` spacers before the closing tokens, the owning voice's spacer carries a voice level, `dynamics_bar` uses the full length for a part level; remove the `offset < length` filter. CHANGELOG (Fixed).
14. **Record the decisions.** Hairpins' Notes name the shared mechanisms and the LilyPond end-of-music caveat; fix links to this story's location.

### Testing Strategy

- Round trips assert `[owner, position, level]` for every dynamic through a shared helper in `spec/support/`, not the level in force at each note.
- Voice events are compared by `to_s`, so a held note that comes back split fails.
- Fixtures come from `HeadMusic::Notation::ABC.parse` plus `place_dynamic`: a whole note with *p* at 1:2, a dotted quarter with *p* at 1:1:480, one tick into a whole note, two parts, a grand staff, a tie across a barline, a pickup, and `C D E` in 4/4 with trailing voice and part dynamics.
- Every new LilyPond source compiles with `compile_warnings` empty.
- Each new spec is run against the old code (files copied aside, not stashed) to prove it fails.
- No console assertions.

### Risks

- Dropping trailing `ryy` on kern import changes how outside files ending a spine with invisible rests read; run the corpus sweep.
- Kern still writes visible `r` filler for a voice that ends before others and reads it back as a rest; writing it as `ryy` is a follow-up.
- The new readers turn mid-voice `x`, `s`, or `ryy` into visible rests: positions are right, invisibility is lost.
- Overlay rendering and odd lengths such as `x5/2` are unverified in abcm2ps and abcjs.
- Very fine offsets make long `\after` multipliers and many kern null rows; both are bounded and read back exactly.
