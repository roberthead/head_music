<!--
metadata:
  created_at:   2026-09-25T14:05:55-07:00
  activated_at: 2026-09-27T13:53:22-07:00
  planned_at:   2026-09-27T15:48:57-07:00
  finished_at:
  updated_at:   2026-09-27T19:39:24-07:00
-->

# Story: Spans Across Notes: Slurs and Phrase Marks

## Summary

AS a developer or researcher using HeadMusic

I WANT a voice to hold markings that run from one note to another, starting with slurs and phrase marks

SO THAT phrasing survives import, and the gem can reason about phrases and slurred groups

This story adds the span model and its Flow JSON, and slurs and phrase marks in ABC, LilyPond, and kern (read and write) and MusicXML (write). Hairpins and lyric extenders follow in [Hairpins](../backlog/hairpins.md) and [Lyric Extenders](../backlog/lyric-extenders.md), on the same model.

## Background

Some markings belong to a stretch of music, not to one note. Every format has them:

| Concept | ABC | LilyPond | MusicXML | kern | MEI |
|---|---|---|---|---|---|
| Slur | `(CDE)` | `c( d e)` | `<slur>` | `(c d e)` | `<slur>` |
| Phrase mark | — | `\( … \)` | `<slur>` (no separate element) | `{ … }` | `<phrase>` |
| Crescendo, diminuendo | `!<(!` … `!<)!` | `\<` … `\!` | `<wedge>` | `<` and `>` in `**dynam` | `<hairpin>` |
| Lyric extender (melisma) | `_` in `w:` | `__` | `<extend>` | `_` and `\|` in `**text` (read as no syllable today) | `<extend>` |

A slur covers a few notes and means legato; a phrase mark is a longer curve over a whole phrase, often with slurs inside it. LilyPond and kern keep the two apart. ABC has only its `( … )`, and MusicXML writes both as `<slur>`.

The model has none of them. As of `e31cf6a8`:

- **Slurs raise in ABC and LilyPond.** `(CDE)` and `c( d e)` raise `UnsupportedFeatureError`. LilyPond's `\(` and `\=1(` raise `ParseError: Unexpected character "\"`, because the lexer takes them for malformed commands, and `^(` and `_(` raise `UnsupportedFeatureError`. Syntax that is valid but unsupported should not raise a parse error.
- **kern drops them.** The token reader passes over `(`, `)`, `{`, and `}`.

Slurs matter to this gem beyond display: in vocal music a slur marks a melisma, and a phrase mark states where a phrase ends, which a style guide could use.

This story comes after [Articulations, Ornaments, Dynamics](../done/articulations-ornaments-dynamics.md) and [Markings Review Follow-ups](../done/markings-review-follow-ups.md), and builds on their shapes:

- `KeyedCatalog` for the kinds of span.
- Position-keyed events and their sorted collections, as `DynamicEvent` and `DynamicEvents` are.
- Optional keys within Flow JSON schema 5, validated through `SchemaValues` with path-tagged errors.
- `BarSplitter.segments_of`, which splits a note at a barline into the fragments a writer writes.

### Lessons carried over

- **`expect_same_markings` compares only the level in force at each note.** It cannot see a span that moved. Round trips here assert where each span starts and ends.
- **Check every helper that does arithmetic on a flow's timeline against spans** before calling a format done. See the checklist in the plan.
- **A format that cannot hold everything keeps what it can.** ABC writes a phrase mark as a slur rather than dropping the curve.

## Example

```ruby
voice.add_span(:slur, from: "1:1", to: "1:3")
voice.add_span(:phrase, from: "1:1", to: "4:1")

voice.spans_at("1:2").map(&:kind) # => [:slur, :phrase]
```

## Acceptance Criteria

### Model

- [ ] A voice can hold spans, each with a kind (slur or phrase) and a start and end position, via `voice.add_span(kind, from:, to:)`
- [ ] A span kind declares its rules as data: whether its ends sit on note events, on voice events, or at any position; whether a voice, a part, or both may hold it; and whether it covers its last note. Hairpins, octave lines, pedals, and glissandos can be added later without changing the span's shape
- [ ] Span storage does not depend on its owner, so a part can hold spans in a later story
- [ ] A slur whose start or end is not a note event of its voice raises `ArgumentError`, and so does a phrase whose start or end is not a voice event of its voice (a phrase may begin or end on a rest), a span whose end does not come after its start, and an exact duplicate
- [ ] Slurs may nest inside phrase marks and cross them. Two slurs, or two phrases, in one voice may nest or overlap, and both are kept
- [ ] A span can cross barlines and staff crossings, and writers open it on the first fragment of its first note and close it on the last fragment of its last note
- [ ] Merging a chord tone onto a slurred note, or placing a rest on it, leaves the slur unchanged; placing a note on a rest that a phrase starts or ends on leaves the phrase on the new note
- [ ] `voice.spans_at(position)` answers each span with `from <= position` whose last note has not yet ended, innermost first

### Serialization and formats

- [ ] Flow JSON writes `"spans"` on a voice only when it has spans, as an optional schema-5 key validated with path-tagged errors; existing schema-5 documents read unchanged
- [ ] ABC reads `(`/`)` slurs, including nested and dotted `.(` ones, and writes slurs, and phrase marks as slurs; it leaves out a phrase that would cross a slur, raises `RenderError` for two slurs that cross, and a spec pins both; `(3` still raises `UnsupportedFeatureError`
- [ ] LilyPond reads `(`/`)`, `\(`/`\)`, `^(`/`_(`, and `\=id(` slurs, and writes slurs and phrasing slurs, numbering them as `\=n(` only where two of a kind are open at once
- [ ] kern reads and writes `(`/`)` slurs and `{`/`}` phrases, including nested ones, and elided `&` ones as overlaps
- [ ] MusicXML writes `<slur>` for slurs and phrases, numbering spans open at the same time so crossing slurs survive
- [ ] Each format round-trips a flow with a slur nested in a phrase, a slur whose last note is tied across a barline, and a slur across a staff crossing, asserting where each span starts and ends; ABC's phrases come back as slurs, and a spec pins that
- [ ] Readers keep phrases that start or end on a rest, and drop unmatched, unterminated, and zero-length spans and rest-anchored slurs instead of raising; every file that imports today still imports
- [ ] LilyPond's `\(`, `\)`, and `\=id(` no longer raise `ParseError`
- [ ] Maintains 90%+ test coverage

## Notes

- Octave lines (8va), pedal marks, and glissandos are also spans. They are out of scope, but a span kind's rules are data, so each is a catalog row later rather than a change of shape.
- Ties are not spans: the model already holds them in the tied chain of a rhythmic value.
- Slurs must start and end on note events, since legato needs sounding notes; readers drop one anchored on a rest, which keeps imports working. A phrase may start or end on any voice event, rests included, since a phrase often ends in one.
- A slur starting on a grace note, which the readers drop, moves to the next main note. [Tuplets and Grace Notes](../backlog/tuplets-and-grace-notes.md) should revisit that.
- `Voice#voice_events` answers its live array, so code outside the gem could move an event out from under a span. Nothing in the gem does; freezing or copying it is a later refactor.
- Crossing slurs in kern are written with `&(`, trusting the Humdrum elision convention. No Humdrum tool was run to confirm it reads as an overlap; if it proves not to, kern should raise `RenderError` for them like ABC.

## Resolved Questions

1. **Positions, not voice event references.** `Voice` cannot remove or move a voice event, and `Voice#merge_at` never changes what sits at a position: a chord tone merges into the event, a rest placed on anything is ignored, and a note placed on a rest replaces it with the same rhythmic value. So a span checked when it is added cannot dangle, and positions serialize without event ids. Every reader can add a span after its notes are placed.
2. **No melisma inference.** The gem stores only what a file says. An analysis method can come later, when a guide needs one.

## Implementation Plan

### Overview

A voice gets spans: each a kind, a start position, and an end position. Kinds come from a `SpanKind` catalog that states each kind's rules as data. Spans live in a `Spans` collection that works for any owner, so a part can hold hairpins later. Each step below is one commit, adds its CHANGELOG line under Unreleased/Added, and runs the touched specs, `bundle exec rake`, and `bundle exec rubocop -a` first. Nothing is **Breaking.**: every key is new and optional, and every reader keeps what it raised on or dropped before.

### Steps

1. **`SpanKind` catalog**
   - Built as `Rudiment::Dynamic` and `Articulation` are: `load_catalog`, frozen instances, aliases.
   - Records: `slur`, and `phrase` (aliases `phrasing_slur`, `phrase_mark`). As built, the hairpin records wait for [Hairpins](../backlog/hairpins.md), which decides what their ends sit on; a catalog row with an undecided anchor would let a voice hold a crescendo this story cannot write.
   - Each record states its rules: `anchor` (`note_events` for slur, `voice_events` for phrase; hairpins decided in their story), `extent` (`through_note` for slur and phrase, `to_position` for hairpins), and `owners` (`[voice]` for slur and phrase, `[voice, part]` for hairpins).
   - Names in all six locales and en_GB.
   - Files: `rudiment/span_kind.rb`, `rudiment/span_kinds.yml`, `locales/*.yml`, `lib/head_music.rb`.
   - Spec: `spec/head_music/rudiment/span_kind_spec.rb`, mirroring `dynamic_spec.rb`.

2. **`Span`, `Spans`, and the Voice API**
   - `Content::Span` is a frozen value modeled on `DynamicEvent`: `flow`, `span_kind`, `kind`, `from`, and `to`. It coerces positions, raises on a foreign flow, requires `from < to`, answers `to_h` as `{"kind", "from", "to"}`, and compares on `[from, to, kind index]` so JSON is deterministic.
   - `Content::Spans` is a sorted collection like `DynamicEvents`. Its owner hands it the anchor check, so it never branches on owner type. It raises only on an exact duplicate, and answers `starting_at`, `ending_at`, and `covering(position)`.
   - `Voice#add_span(kind, from:, to:)` checks each end against `voice_event_at` by the kind's anchor: a slur needs a `NoteEvent`, a phrase any voice event. It also raises when the kind's `owners` leaves out a voice. `Voice#spans` answers them.
   - `Voice#spans_at(position)` is half-open, `from <= position < extent_end`, where a `through_note` span's `extent_end` is the `next_position` of the note at `to`. It answers the innermost first.
   - Files: `content/span.rb`, `content/spans.rb`, `content/voice.rb`, `lib/head_music.rb`.
   - Specs (`span_spec.rb`, `spans_spec.rb`, `voice_spec.rb`):
     - a slur nested in a phrase, and one crossing it
     - two overlapping slurs kept
     - touching slurs that share an end
     - an exact duplicate raising
     - an end on a rest or on no event raising
     - `from == to` and `to < from` raising
     - a chord tone merged onto a slurred note, and a rest placed on one, leaving the slur
     - slurs across a barline and a `cross_to`
     - `spans_at` at the start, inside the last note, and at the last note's `next_position`

3. **Flow JSON**
   - `Voice#to_h` writes `"spans"` only when there are some.
   - `SchemaValues#spans(values, path)` validates with `each_element`, `catalog_value`, and `position`, so errors read like `parts[0].voices[1].spans[3].to`.
   - `hash_deserializer.rb` adds spans after the voice events and dynamics are placed, re-raising `add_span`'s `ArgumentError` with the entry's path.
   - Specs: `flow_serialization_spec.rb` (round trip, no key without spans, a schema-5 document without spans), `schema_values_spec.rb` (path-tagged errors for a bad kind, a bad position, and an end off an event).

4. **Shared fixtures and `expect_same_spans`**
   - `spanned_melody`, built with `ABC.parse` where ABC can say it:
     - a phrase over bars 1–4 with a slur nested in it
     - two slurs sharing an end
     - a slur ending on a note tied across a barline
     - a slur starting on a note split at a barline
     - a nested pair of slurs
   - `crossing_slurs`: two slurs that overlap without nesting.
   - `spanned_piano`: `cross_staff_piano` with a slur across the staves.
   - `expect_same_spans(original, round_tripped)` compares `[kind, from, to]` for every voice.
   - File: `spec/support/marking_fixtures.rb`.

5. **kern: read slurs and phrases**
   - `token_reader.rb`: `(`, `)`, `{`, `}`, and `&` leave the ignored set; a token counts its opens and closes, combined across a chord.
   - `voice_cursor.rb#continue_tie`: a mark on a tie's later link belongs to the tie's voice event.
   - `layer.rb`: after the notes are placed, pair opens with closes per layer. `((` nests; `&(` elides into an overlap. Unmatched marks, slur marks on rests, marks on grace notes, pairs that collapse to `from == to`, and unclosed spans are skipped; a phrase mark on a rest is kept.
   - Specs: `token_reader_spec.rb`, `flow_builder_spec.rb`, `flow_builder_splits_spec.rb` (a slur in a sub-spine).

6. **kern: write slurs and phrases**
   - `spine_tokens.rb#event_for`: opens on the first link of the start event, closes on the last link of the end event, once per chord, ordered `{(4c` … `4e)}`. Nested slurs repeat the mark; crossing ones use `&`.
   - Specs: `writer_spec.rb`; `kern_round_trip_spec.rb` with `expect_same_spans` on all three fixtures.

7. **ABC: read slurs**
   - `body_lexer.rb`: `(` not followed by a digit lexes as a slur start, `)` as a slur end, and `.(` as a slur; `(3` still raises `UnsupportedFeatureError`.
   - `voice_state.rb`: a pending start rides on the next note; `)` marks the pending note; `flush_pending_note` adds the span. `((CD)E)` gives two spans. Unmatched marks and slurs on rests are dropped; a slur starting on a dropped grace note moves to the next main note, or is dropped if that leaves it zero-length.
   - Specs: `body_lexer_spec.rb` (the `(` and `)` unsupported cases change), `parser_spec.rb`, `voice_state_spec.rb`.

8. **ABC: write slurs, and phrases as slurs**
   - `(` goes before the decorations on the start event's first segment, `)` after the end event's last segment. Slurs and phrases write alike, nested as nested parentheses.
   - A phrase that would cross a slur is left out. Two slurs that cross raise `ABC::RenderError`.
   - Specs: `writer_spec.rb`; `abc_round_trip_spec.rb` with `expect_same_spans` on slurs, a spec pinning that phrases come back as slurs, and `crossing_slurs` raising.

9. **LilyPond: read slurs and phrasing slurs**
   - `lexer.rb`: `\\[()]` joins `MARK_PATTERN`, `\=id(` and `\=id)` lex, and the direction prefixes `^(` and `_(` are accepted.
   - `mark_reader.rb`: `Marks` gains slur and phrase opens and closes.
   - `event_placer.rb`: open spans are tracked per voice, keyed by id so `\=1(` and `\=2(` can overlap, and added when the end note is placed. A mark on a tie's later link goes to the start of the tied group. Slur marks on rests, unmatched marks, and unterminated spans are dropped; a phrasing slur on a rest is kept.
   - Specs: `lexer_spec.rb`, `mark_reader_spec.rb`, `document_reader_spec.rb` (`(` leaves the unsupported list). Edit these with the Edit tool; they are full of backslashes.

10. **LilyPond: write slurs and phrasing slurs**
    - `mark_writer.rb` writes `(` or `\(` on the start event's first fragment, and `)` or `\)` on the last word of the end event's last fragment (`c2~ c4)`).
    - Where two slurs, or two phrases, are open at once, the writer numbers them `\=1(` … `\=1)` and `\=2(` … `\=2)`; otherwise it writes plain marks. A slur inside a phrase needs no number.
    - Extend `SIMPLE_TOKEN` and `strip_commands` in `spec/support/lily_pond_helpers.rb` first.
    - Files: `mark_writer.rb`, `render_plan.rb` (`#token`, `#marks`), `voice_stream.rb` (`extend_tie` merges span marks rather than holding them).
    - Specs: `writer_spec.rb`; `lily_pond_round_trip_spec.rb` with `expect_same_spans` on all three fixtures, `crossing_slurs` included.

11. **MusicXML: write `<slur>`**
    - `<slur type="start|stop" number="n"/>` in `<notations>` on the chord's lead note: start on the first component (`!tie_stop`), stop on the last component of the segment that does not continue.
    - Phrases write as `<slur>` too. Each span open at once gets its own number, 1–16; more than 16 at once raises `RenderError`.
    - `divisions.rb` needs no change, since slur ends are voice-event starts; a spec pins that.
    - Specs: `writer_spec.rb` (`crossing_slurs` numbers), `writer_cross_staff_spec.rb` (a stop on the other staff), `divisions_spec.rb`.

12. **Grading guard**
    - Add a slur and a phrase to the marked copy in `guide_marked_flow_grading_spec.rb`, and assert every guide grades it the same.

### Timeline-helper checklist

- [ ] `BarSplitter.segments_of`: opens go on the first fragment of the start event, slur and phrase closes on the last fragment of the end event
- [ ] MusicXML `Divisions`: unchanged for voice spans; pinned
- [ ] MusicXML `NoteWriter` tie components: start on `!tie_stop`, stop on the last `!tie_start`
- [ ] kern `SpineTokens#event_for`: opens at the first link, closes on the last
- [ ] kern `VoiceCursor#continue_tie`: marks on later links belong to the tie's event
- [ ] LilyPond `RenderPlan#token` and `#marks`, and `VoiceStream#extend_tie`: closes on the last word of a tied group
- [ ] ABC writer segment loop: `(` and `)` around the right segments
- [ ] `Flow#latest_bar_number` and the writers' bar numbering count voice events only

### Testing strategy

- Every round trip calls `expect_same_spans` on `spanned_melody` and `spanned_piano`, comparing `[kind, from, to]`.
- The fixture's traps: a slur ending on a note tied across a barline, one starting on a note split at a barline, and one crossing staves.
- Losses are pinned: ABC phrases return as slurs, ABC leaves out a phrase that crosses a slur and raises on `crossing_slurs`, and LilyPond and MusicXML number them. `spanned_melody` gains a phrase ending on a rest, and one crossing a slur.
- Each reader gets a table spec of what it keeps and drops: nested, crossing or elided, unmatched, on a rest, on a grace note, on a tie's later link, and unterminated. `(3` in ABC still raises; `\(` and `\=1(` no longer do; existing fixtures still import.
- Each new reader and writer spec is run once against the code before its change, to see that it fails.
- Coverage stays at 90% or more under `bundle exec rake`.

### Risks

- Kern's `&(` as an overlap is unconfirmed against a Humdrum tool.
- Readers that drop rest-anchored slurs keep imports working, but lose the mark. That is the reader policy.
- Implementation pauses after step 3, so the model and JSON can be checked before the formats build on them.
- `spans_at` is half-open with a per-kind extent, so a slur covers the whole of its last note; hairpins will end at a position instead.
