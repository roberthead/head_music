<!--
metadata:
  created_at:   2026-07-19T16:21:53-07:00
  activated_at: 2026-07-19T18:37:53-07:00
  planned_at:   2026-07-19T18:09:39-07:00
  finished_at:  2026-07-19T20:10:12-07:00
  updated_at:   2026-07-19T20:10:12-07:00
-->

# Story: ABC Notation Beaming

## Summary

AS a dev
I WANT to be able to represent beaming in an ABC import
SO THAT notation I generate from the resulting Composition has beaming.

## Acceptance Criteria

### Default meter-derived beaming (MusicXML output)

- In a simple meter (2/4, 3/4, 4/4), `MusicXML::Writer` emits `<beam>` elements that group consecutive sub-quarter notes by beat (the count unit).
- In a compound meter (6/8, 9/8, 12/8), beam groups follow the dotted-quarter pulse — three eighths per group — not the individual eighth. (This is the case OSMD's renderer default gets wrong.)
- Beam elements read `begin` on the first note of a group, `continue` in the middle, and `end` on the last; a lone flagged note in its own group emits no beam.
- The `number` attribute reflects the beam level (eighth = 1, sixteenth = 2, …), and mixed values within a group (e.g. an eighth followed by two sixteenths) nest the levels correctly.
- Quarter-or-longer notes and rests terminate the current beam group — no beam spans them.
- Beam grouping resolves at the notated-note (`Component`) level, so a note that expands into a tied chain still beams correctly across the tie.
- Beam groups never cross a barline or a beat/pulse-group boundary.

### Authored-group capture from ABC (override)

- The ABC body lexer preserves inter-note spacing as a beam signal instead of silently discarding it (today: `body_lexer.rb:114` skips `/[ \t]+/` with no token).
- Adjacent note tokens with no separating space import as one beam group; a space breaks the group — matching ABC's beaming convention.
- When ABC source expresses an explicit grouping, that authored grouping overrides the meter-derived default on output (the "deliberate deviation" case, same default-vs-override shape as ties).
- A placement with no authored beam signal falls back to the meter-derived default; an explicit signal is honored verbatim.

### ABC export round-trip

- The ABC writer suppresses the inter-placement space *within* an authored beam group and emits a space at group boundaries, so an authored grouping survives parse → write → parse without loss (today `writer.rb:118` joins every placement with a space, breaking every beam).

## Notes

### Why this feature exists

OSMD's renderer-side default beaming can't handle compound meters, which are central to the material here (6/8 now; counterpoint lives in 3/4, 6/4, cut time…). So head_music must emit beams explicitly rather than lean on the renderer. Consumers render with **autoBeam off** — explicit beams are then authoritative and portable (MuseScore and Dorico honor them too).

### How beaming is represented (design recommendation)

Beaming is **not** modeled like ties. Ties fold into a single `RhythmicValue.tied_value` chain (contained within one note); beaming is a *grouping across multiple notes*, so it cannot live inside one `RhythmicValue`. Two representations, matching the default-vs-override shape:

1. **Default beaming — no model state.** `MusicXML::Writer` derives groups on the fly from `Meter#compound?` / `Meter#beat_value` (`meter.rb:90-100`) plus each note's position and type. A programmatically-built Composition, or ABC with no grouping intent, carries nothing extra.
2. **Authored override — a lightweight per-`Placement` flag.** In ABC a beam break can only fall *between* note tokens (a space), never inside a single note, so a placement-level signal (e.g. `beam_break_before` / "beamed-to-previous", `nil` by default) is sufficient. This mirrors the side-metadata flags `Bar` already carries (`starts_repeat`, `plays_on_passes`) rather than baking state into `RhythmicValue`. Concrete attribute name is a planning decision.

At render: an explicit placement flag is honored (override); `nil` falls back to the meter default. Within a placement that expands to a tied chain, the internal component-to-component beams still follow type-based rules — the flag only governs the boundary *between* placements.

### Code map (from exploration)

- **Meter grouping primitives** — `Meter#compound?` (`top > 3 && top % 3 == 0`), `Meter#beat_value`/`beat_unit` (dotted-quarter for compound, count unit for simple), `Meter#beats_per_bar`: `lib/head_music/rudiment/meter.rb:38-44, 58-64, 90-100`. Edge case: **3/8 reports `simple?`** (fails `top > 3`) — confirm desired grouping.
- **MusicXML `<beam>` emission** — insert into `note_element_lines` after `<dot>`/`<stem>` and before `<notations>`: `lib/head_music/notation/music_xml/writer.rb:341-353`. A `Component` is one notated notehead (`duration_writer.rb:7, 44-65`); a placement can expand into several via a tied chain, so beams resolve at the Component level in `note_lines` (`writer.rb:313-321`). No `beam` string exists in `lib` today.
- **ABC lexer capture** — change the discard at `lib/head_music/notation/abc/body_lexer.rb:114`; add token field(s) near `body_lexer.rb:12-25`.
- **ABC parser** — placement creation at `parser.rb:165-169, 214-221, 343-349` needs to carry the beam signal onto the Placement (compare with how `tie` state threads through `VoiceState`).
- **Placement model** — no beam attribute today: `lib/head_music/content/placement.rb:5-8`.
- **ABC export** — space-joining to make conditional: `lib/head_music/notation/abc/writer.rb:112-120`.

### Reference

Follow the tie feature as the architectural template: `user-stories/done/abc-tie-input.md`. Note the key difference — ties collapsed to the input boundary because the render path already existed; beaming has **no existing data path at all** (new model state + MusicXML emission + ABC space-suppression), so it is a larger change.

## Review

_Reviewed 2026-07-19 at commit `cd35e95` (feature), by product-manager (acceptance criteria) and code-reviewer (code quality). Two follow-up fixes were applied after the review and are described below._

### Acceptance criteria

All 12 criteria **✅ met**, each backed by code and a passing test (full suite green, 5938 examples).

**Default meter beaming (MusicXML)**

- ✅ Simple meter groups sub-quarter notes by beat — `meter.rb` `beam_group_unit` + `writer_spec` "eight default-beamed eighths in 4/4".
- ✅ Compound meter groups by the dotted-quarter pulse (the renderer-fails case) — `writer_spec` "six default-beamed eighths in 6/8" → two 3-groups.
- ✅ begin/continue/end; lone note emits no beam — `beam_grouper_spec` size-1 group → `[]`.
- ✅ `number` = beam level; mixed values nest — `writer_spec` dotted-eighth + sixteenth (level-1 end + level-2 backward hook).
- ✅ Quarter-or-longer notes and rests terminate a group — `writer_spec` quarter/rest break cases.
- ✅ Resolves at the Component level; beams across a tied chain — `writer_spec` "tied chain of two eighths inside one beat group".
- ✅ Never crosses a barline or beat/pulse boundary — per-bar annotation + modulo check; pickup-bar test.

**Authored ABC capture (override)**

- ✅ Lexer preserves inter-note spacing as `:beam_break` — `body_lexer_spec`.
- ✅ Adjacent → one group, space → break — `parser_spec` flag-sequence tests.
- ✅ Authored grouping overrides the default — `writer_spec` "authored ABC beam grouping in 4/4".
- ✅ No signal → meter default; explicit honored — `beam_grouper_spec` tri-state tests.

**ABC export round-trip**

- ✅ Space suppressed within a group, kept at boundaries; survives parse→write→parse — `abc/writer_spec` idempotence + `composition_serialization_spec` JSON round-trip.

### Code review findings

- **Medium — asymmetric simple meters crashed `beam_group_unit`** (`meter.rb`): 5/16, 7/16, etc. produced a non-power-of-two unit → `nil` → `DelegationError` instead of a graceful result, violating the "out of scope but must not crash" constraint. **Fixed:** the duple whole-bar branch now falls back to the count unit when `for_denominator_value` returns `nil`; added `meter_spec` rows for 5/16 and 7/8.
- **Nit — local `groups` shadowed the method `#groups`** (`beam_grouper.rb`). **Fixed:** renamed the accumulator to `result`.
- Positives noted: `BeamGrouper` is genuinely pure; integer-only onset arithmetic (no Float drift); the component-vs-placement granularity risk is handled correctly (flag only on component 0, onset accumulates per component); `false`-join correctly cannot bridge a rest/quarter; high-quality XML-output assertions.

### Manual verification (not blockers)

- The MusicXML `<beam>` output has **not** been opened in a real notation reader (MuseScore/Finale/Sibelius). The tests assert correct XML structure; a one-time visual eyeball — especially the 6/8 case and hook direction — is worth doing.

### Verdict

Shippable. Both review findings have been fixed; nothing blocks `finish`. Recommend committing the two fixes before finishing.

## Implementation Plan

### Overview

Beaming is emitted at MusicXML render time from a new stateless helper `HeadMusic::Notation::MusicXML::BeamGrouper`, fed a measure's ordered noteheads and the meter's beam-group unit. Default grouping needs zero model state; ABC-authored grouping is captured as a tri-state `beam_break_before` flag on each `Placement` (the `Bar`-style side-metadata pattern) that overrides the default at placement boundaries. Build in two internally-ordered layers that ship together: default render (Steps 1-3), then authored override (Steps 4-7).

**One "confirmed" assumption is corrected here.** The brief said "simple meter → group by beat (count unit)." Grouping 3/8 by its count unit (the eighth) makes every eighth its own group and emits **no** beam — contradicting the confirmed "3/8 → one group of three eighths." The grouping unit is therefore **not** `Meter#beat_value` for eighth/sixteenth-denominator simple meters. Step 1 introduces a distinct `Meter#beam_group_unit` (whole bar for 3/8 and 2/8, the beat for quarter-or-larger simple meters, the dotted-quarter pulse for compound). 3/8 stays `simple?`; only the beam-grouping unit differs.

### Scope

- **v1 (ships together):** default beaming for simple (2/4, 3/4, 4/4, 3/8) and compound (6/8, 9/8, 12/8) meters; eighths and sixteenths with correct primary (level 1) and secondary (level 2) beams **including forward/backward hooks** (dotted-eighth + sixteenth is ubiquitous and cannot be omitted without visibly wrong output); authored override via the per-Placement flag, honored on render and preserved through ABC export round-trip. Layers 1 and 2 must land in one story — the override is only observable as a deviation from the default, so the default must exist to test it.
- **Deferred, each with a defined behavior:** 32nd-and-finer levels (logic generalizes but assert only to level 2); tuplet beaming (tuplets already unsupported at the ABC boundary); beaming across a barline (MusicXML forbids it; `ensure_notes_within_barlines` enforces it — beam simply breaks at the barline, silently, matching the tie feature's barline behavior); beam-over-rest (rests always break a group in v1); feathered/cross-staff/slope beams (not expressible in ABC).

### Steps

**1. `Meter#beam_group_unit` — the grouping-boundary source (domain rudiment)**

- Add a method returning the beam-group span as a `RhythmicValue`: dotted-quarter for `compound?`; the whole-bar value for eighth/sixteenth-denominator simple meters (3/8, 2/8); the beat (`count_unit`) for quarter-or-larger simple meters. Keep `beat_value`/`beat_unit` untouched — this is a separate concern (where beams break vs. where beats fall).
- Files: `lib/head_music/rudiment/meter.rb` (new method near `beat_value` :90-100; reuses `compound?` :42-44, `count_unit` :86-88, `top_number`/`bottom_number`).
- Tests: `spec/head_music/rudiment/meter_spec.rb` — table-driven across 4/4, 3/4, 2/2, **3/8**, 2/8, 6/8, 9/8, 12/8, asserting the group unit (and its tick/division span). This single spec regression-locks the 3/8 decision.

**2. `BeamGrouper` helper — pure, fully unit-testable (default beaming logic)**

- New `HeadMusic::Notation::MusicXML::BeamGrouper`, same shape as `Divisions`/`DurationWriter`/`ClefSelector`. Consumes an ordered list of per-notehead events for one measure plus the group-unit span; returns per-event `<beam>` annotations. No XML strings — return plain structs (mirror `DurationWriter#components` :44-47) so grouping is testable in isolation.
- Suggested shape:
  - `Beam = Struct.new(:number, :type, keyword_init: true)`, `type ∈ "begin"|"continue"|"end"|"forward hook"|"backward hook"`.
  - `Event = Struct.new(:levels, :onset, :beam_break_before, keyword_init: true)` — `levels` = beam count the notehead carries alone (eighth=1, 16th=2, 32nd=3 via a table keyed on `DurationWriter::TYPES_BY_UNIT_NAME` :11-24; `0` for a rest or quarter-or-longer); `onset` = integer offset from bar start **in divisions** (integer, not ticks — avoids Float; see risk note); `beam_break_before` meaningful only on a placement's first component.
  - `BeamGrouper.for(events, group_unit_divisions) → Array<Array<Beam>>` parallel to `events`.
- Algorithm — segment then emit:
  1. Boundary before event `i` when any of: `events[i].levels.zero?` or `events[i-1].levels.zero?` (rests / quarter+ are hard breaks and are singletons); `beam_break_before == true` (force break); `beam_break_before == false` (force join, overrides the default boundary); `nil` → default boundary iff `onset % group_unit_divisions == 0`.
  2. Per group: size 1 → `[]` (lone-note no-beam case). Else level 1 spans the group (begin/continue/end). For each level `k ≥ 2`: runs of consecutive members with `levels ≥ k` emit begin/continue/end; a level-`k` member isolated between lower-level neighbours is a **hook** — backward if its predecessor is lower (dotted-eighth + 16th), forward if its successor is.
- Per-level nesting requires independent open/close tracking per level, not one group cursor.
- Tests: `spec/head_music/notation/music_xml/beam_grouper_spec.rb` — two eighths → begin/end L1; four eighths across two beats (all-nil) → two pairs; eighth + two 16ths → L1 begin/continue/end + L2 begin/end; dotted-eighth + 16th → L2 backward hook; level-0 mid-run splits and gets `[]`; size-1 group → `[]`; `beam_break_before:false` overriding a boundary → single group; `beam_break_before:true` mid-beat → split.

**3. Emit `<beam>` from the Writer, driven by `BeamGrouper` (completes Layer 1)**

- Build a memoized `beam_annotations` hash keyed by `[placement, component_index] → Array<Beam>`. For each voice/bar, iterate `placements_by_bar` (:292-295) in position order and construct the ordered `Event` list:
  - **Onset must derive from `placement.position` (count/tick), not from the Component** — the Component carries no position. This is what makes anacrusis/pickup bars land on the correct metric grid: a 6/8 pickup eighth on count 6 groups as the bar's last pulse, not as offset 0. Compute the placement's bar-start offset in **divisions** (mirror the exact-integer arithmetic of `whole_measure_duration` :308-310), then accumulate each subsequent tied-chain component's `component.duration` (already integer divisions) onto it.
  - Walk `components_by_placement[placement]` (:117-121) parallel to the `tied_value` chain. Per component: `levels` from its own `type` (0 if `placement.rest?`); `beam_break_before` = `placement.beam_break_before` on `component_index == 0`, else nil. Internal tied-chain beams thus follow type rules; the flag only governs the boundary between placements.
  - `group_unit_divisions` from `effective_meter(bar_number).beam_group_unit` (Step 1) converted to divisions.
  - Call `BeamGrouper.for(...)`; store under `[placement, i]`.
- `note_lines` (:313-321): change the outer `flat_map` to `each_with_index.flat_map` for `component_index`; look up the annotation; pass `beams:` into `note_element_lines` **only on the lead slot** — `beams: index.zero? ? beams : []` (MusicXML puts `<beam>` on the chord's primary note, never on `<chord/>` members).
- `note_element_lines` (:341-353): add `beams: []` kwarg; insert `*beam_lines(beams)` **between** the dots line (:349) and `*notation_lines` (:350) — after `<dot>`, before `<notations>`, per the DTD. `beam_lines` maps each `Beam` to `<beam number="N">type</beam>`.
- Tests: `spec/head_music/notation/music_xml/writer_spec.rb` — 4/4 eight eighths → four two-note groups (assert exact begin/end and that no beam crosses a beat); 6/8 six eighths → exactly two three-note groups (the OSMD-failure case, asserted directly); a quarter/rest between eighths breaks the group and emits no `<beam>`; a chord of eighths carries beams only on the non-`<chord/>` note; a lone eighth emits no `<beam>`; assert exact line placement relative to `<dot>`/`<notations>`.

**4. Per-`Placement` `beam_break_before` flag + override wiring (starts Layer 2)**

- Recommended name/semantics: **`beam_break_before`**, tri-state — `nil` = default/meter-derived (**nil ≠ false**), `true` = force a break here, `false` = force beamed-to-previous. Reserve all three states now: a nil/true-only boolean can add a break but can never join across a default boundary, which is exactly what fully-authoritative ABC needs.
- Follow the `Bar` side-metadata precedent (`starts_repeat`, `plays_on_passes`, `bar.rb`): add a writable attribute (`attr_accessor :beam_break_before`, default nil) set on the placement **after** construction, rather than threading a new positional/keyword arg through `Voice#place` and `Placement.new`. Placement already mutates via `merge` (:61-69) and `Voice#place` returns the instance, so the parser can set the flag on the returned object — this leaves the `place`/constructor/`merge` contract untouched.
- In `merge`, the receiver's flag wins (chord members at one position share one beam edge) — pin with a spec.
- The writer already reads `placement.beam_break_before` in Step 3's event construction; with the attribute defaulting to nil, Steps 1-3 render unchanged until the parser populates it.
- Files: `lib/head_music/content/placement.rb` (:5-15 attr, `merge` :61-69). Tests: `spec/head_music/content/placement_spec.rb` — default nil; `merge` keeps the first flag; a non-nil flag flows into the Step-3 event and changes the emitted grouping.

**5. ABC lexer — capture inter-note spacing as a `:beam_break` token**

- Emit a standalone `:beam_break` token (mirroring the separate `:tie` token, `scan_tie` :285-290) rather than adding a field to every note/chord/rest `Token` — keeps the `Token` struct (:12-25) and localizes the change. At :114, replace the silent `scanner.skip(/[ \t]+/)` discard with: skip the whitespace, and if it separated two music tokens (`tokens.last` is a note/chord/rest) push `Token.new(type: :beam_break, ...)`. Emitting on any skipped run is harmless; the parser consults it only when a note follows.
- Files: `lib/head_music/notation/abc/body_lexer.rb:114`. Tests: `spec/head_music/notation/abc/body_lexer_spec.rb` — `"CC"` → two `:note`, no `:beam_break`; `"C C"` → `:note`, `:beam_break`, `:note`; comment/continuation handling (:115-116) unaffected.

**6. ABC parser — thread the signal onto placements (mirror the tie state machine)**

- Extend `VoiceState` (:50-58) with `beam_break_pending` and `beam_last_was_note` accessors (parallels `tie_open`/`tie_line` :52-53). Add `when :beam_break then handle_beam_break(token)` to the dispatch (:152-163); `handle_beam_break` sets `beam_break_pending = true`.
- In `defer_placement` (:214-221), compute the flag as the note is deferred: `state.beam_break_pending ? true : (state.beam_last_was_note ? false : nil)`; carry it to `flush_pending_note` (:343-349) and set it on the placement returned by `state.voice.place(...)` (the Step-4 setter). Then reset `beam_break_pending = false; beam_last_was_note = true`. For a tie continuation (`tie_onto_pending` :240-249) keep the flag on the head of the fused chain only.
- Reset adjacency at hard boundaries so a following note is not marked "beamed to previous": `handle_rest` (:260-266), `handle_bar_line` (:292-301), `handle_voice_change` (:315-323) set both `beam_last_was_note = false` and `beam_break_pending = false`. First-of-bar/post-rest notes thus stay nil → meter default.
- Net: no-space adjacency → `false` (join), space-separated → `true` (break), first-of-run → `nil` (default). This makes ABC input fully authoritative (matching the OSMD-autoBeam-OFF contract), which is the recommended direction for the beat-crossing question below.
- Files: `lib/head_music/notation/abc/parser.rb`. Tests: `spec/head_music/notation/abc/parser_spec.rb` — `"CCCC"` → flags `[nil,false,false,false]` → one four-note group; `"CC CC"` → `[nil,false,true,false]` → two groups; a rest resets (`"CC z CC"`); tie interaction (`"C-C DD"`).

**7. ABC export — space-suppression for round-trip**

- In `build_bar_strings` (:112-120), replace the literal `" "` join (:118) with a per-adjacency separator: emit `""` before a placement whose `beam_break_before == false` (join), otherwise `" "` (covers `true` and `nil`, preserving today's behavior for unflagged programmatic compositions). Only valid between self-delimiting tokens (notes/chords/rests all re-lex unambiguously).
- Also add the non-nil flag to `Placement#to_h` (sparsely, mirroring how `Bar` serializes only non-default state) so an ABC → Composition → serialize cycle doesn't silently drop authored beaming.
- Files: `lib/head_music/notation/abc/writer.rb:118`, `lib/head_music/content/placement.rb` (`to_h`). Tests: `spec/head_music/notation/abc/writer_spec.rb` — `"CCCC"` re-emits without internal spaces; `"CC CC"` re-emits with the group-boundary space; unflagged programmatic composition still emits spaces (no regression); `ABC.parse(writer.to_s)` reproduces the flags (full round-trip).

**8. Edge-case coverage (cross-cutting)**

- Add to `beam_grouper_spec.rb` (pure) and `writer_spec.rb` / ABC `parser_spec.rb` (end-to-end):
  - **Simple vs compound:** 6/8 → 2 groups of 3; 3/4 → 3 groups of 2; **3/8 → one group of 3** (do not special-case; Step 1 handles it).
  - **Level 2:** eighth + two 16ths → L2 begin/end; **dotted-eighth + 16th → L2 backward hook**; a lone 16th → no beam; a pair of 16ths → both L1 and L2 begin/end.
  - **Quarter/rest breaks:** `"CC A2 CC"` and `"CC z CC"` → separate groups; the quarter/rest emit no `<beam>`.
  - **Tied note beaming across its own components:** a placement whose `tied_value` chain expands to multiple sub-quarter components beams internally by type; the `beam_break_before` flag applies only to `component_index 0`.
  - **Pickup/incomplete bar:** onset from `position` → a partial bar's notes land on correct pulse boundaries; no beam crosses into the next bar.
  - **Back-to-back groups:** `"CCCC CCCC"` → adjacent self-contained groups, no `continue` spanning the boundary.
  - **Authored split below the pulse:** 6/8 `"ab c def"` → `ab` beams, lone `c` no beam, `def` beams — an authored split subdivides inside one dotted-quarter pulse.

### Testing Strategy

Unit-test `BeamGrouper` exhaustively in isolation (data in / data out — the bulk of the correctness lives here, and it mirrors `DurationWriter`'s testable-struct seam). Table-test `Meter#beam_group_unit` separately. Integration-test the `Writer` for exact `<beam>` element placement and levels, and the ABC parse→export round-trip for flag capture and space suppression. Extend existing specs where they exist (`writer_spec.rb`, `body_lexer_spec.rb`, `parser_spec.rb`, ABC `writer_spec.rb`, `placement_spec.rb`, `meter_spec.rb`); add one new `beam_grouper_spec.rb`. Highest-value cases to pin: the 3/8-simple group, level-2 hooks, the rest/quarter break, and the `false`-flag join overriding a default boundary. Prefer building fixtures via `HeadMusic::Notation::ABC.parse` (per project memory). Maintain 90% coverage; run `bundle exec rspec` and `bundle exec rubocop -a` green before finishing.

### Risks & Open Questions

**Ordering / technical risks**

- **Component-vs-Placement granularity (the crux):** the grouper consumes the flattened Component stream, but onsets come from `Placement.position` and only the first component of a placement carries the flag. Reading position off a Component, or letting the `components_by_placement` walk and the `tied_value` chain fall out of sync, misplaces beams — pin with a tied-chain spec.
- **Integer arithmetic:** do onset/boundary math in **divisions** (integer, via `component.duration` and the divisions form of `beam_group_unit`), not ticks. `RhythmicValue#ticks` returns Floats; staying in divisions avoids `.round` drift and matches `whole_measure_duration` (:308-310). If tuplets are ever supported at the ABC boundary, revisit for Rational arithmetic.
- **`<beam>` element order** must be after `<dot>` and before `<notations>` (:349-350); misordering yields invalid MusicXML that some readers silently tolerate — assert exact line order.
- **Chord double-emit:** the `index.zero?` lead-slot guard is essential; a `<beam>` on a `<chord/>` member is malformed.
- **ABC re-lex ambiguity:** space suppression is safe only between self-delimiting tokens (notes/chords/rests); any future token type inside a beam group needs re-checking.

**Resolved decisions** (confirmed by the human, 2026-07-19)

1. **Authored beam crossing a beat/pulse boundary** — **RESOLVED: honor verbatim.** A no-space ABC run beams as one group even across beats (e.g. `cdef` in 4/4 → a single group spanning beats 1-2). ABC spacing is authoritative, matching the "explicit beams win / OSMD autoBeam OFF" purpose. The Step 6 fully-authoritative parser produces exactly this; the grouper honors `beam_break_before == false` as a join across the default boundary.
2. **Partial-beam hooks in v1** — **RESOLVED: yes, include hooks.** Dotted-eighth + sixteenth emits an L2 backward hook. The grouper's `type` vocabulary includes `forward hook`/`backward hook` from the start.
3. **Flag name/polarity** — **RESOLVED: `beam_break_before`**, tri-state (`nil` = meter default, `true` = force break, `false` = force join), a `Bar`-style writable `attr_accessor` on `Placement`.
4. **Export symmetry** — **RESOLVED: asymmetric, like ties.** ABC export only suppresses/emits spaces where an authored flag is present; nil-flag (programmatic) compositions keep today's every-placement spacing. Pin with a round-trip spec.
5. **Authored beam across a barline** — **RESOLVED: silent break at the barline.** The barline terminates any beam (MusicXML forbids cross-barline beams; `ensure_notes_within_barlines` enforces it). This intentionally differs from the tie feature's explicit `ParseError` across a barline.

## Learnings

### What went well

- The core design from planning — **default beaming = no model state (computed at render), authored override = one tri-state `Placement` flag** — held through implementation without rework. Deliberately **not** modeling beaming inside `RhythmicValue` (unlike ties) was correct, since beaming spans notes rather than living within one.
- Making `BeamGrouper` a **pure data-in/data-out helper** put the hardest logic (segmentation, multi-level beams, forward/backward hooks) behind an exhaustive unit spec, isolated from the writer. Most correctness lived there, and testing it in isolation paid off.
- Implementing one step at a time with a review + spec run between each caught the major design tension the moment it appeared, not at the end.

### What was surprising

- The **"honor verbatim" decision has a non-obvious consequence**: ABC adjacency is always authoritative (implies a join), so pure meter-**default** beaming is only observable on programmatically-built compositions. This surfaced mid-implementation as 5 failing writer tests and forced splitting the tests into a default (programmatic) bucket and an authored (ABC-spacing) bucket. Lesson: when an input format is fully authoritative, you cannot exercise the *default* path through that format.
- A **"confirmed" assumption was wrong at an edge**: "simple → group by beat" would make 3/8 emit no beams at all. Planning caught it and introduced `Meter#beam_group_unit` distinct from `beat_value`. Validate confirmed rules against odd cases (3/8) during planning, not after.
- **Lexer/parser signals compose**: a rest is a "beamable predecessor," so `z CC` emits a beam-break and the post-rest note gets `true` rather than `nil`. Harmless (a rest forces a break anyway), but a reminder these signals interact.

### What to do differently

- **Front-load "how is this represented in the model?"** — that question (asked explicitly during the story) is the crux, and answering it early shaped the whole plan. Make it step one.
- The **asymmetric-meter crash (5/16)** slipped past because "don't crash out of scope" was an instruction with no test; code review caught it. When a method becomes public, add a defensive test for out-of-scope inputs.
- **Visual verification in a real notation reader (MuseScore/Finale) is still outstanding** — the suite asserts XML structure, not rendered appearance. Worth a one-time eyeball of the 6/8 case and hook direction.
