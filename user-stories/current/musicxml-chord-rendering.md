<!--
metadata:
  created_at:   2026-07-17T12:54:19-07:00
  activated_at: 2026-07-18T20:22:35-07:00
  planned_at:   2026-07-18T20:30:54-07:00
  finished_at:
  updated_at:   2026-07-18T20:41:11-07:00
-->

# Story: MusicXML Chord Rendering

## Summary

AS a developer using HeadMusic

I WANT `Composition#to_musicxml` to render chord placements as stacked notes

SO THAT block chords display on one staff in MusicXML-consuming renderers (OSMD, MuseScore, etc.)

## Background

The content model represents a chord as a single `Placement` holding two or more pitched sounds (see the Chord Placement Model and Sound Model stories): one position, one rhythmic value, many sounds. `Placement#sounds` (a frozen array) is the source of truth — each sound is a `Rudiment::Pitch` or a `Rudiment::UnpitchedSound` — with `Placement#pitches` as the derived pitched subset and `chord?` true when there are two or more pitched sounds. Because a chord is one placement, `Voice#first_gap` contiguity works by construction — no special grouping is needed. The MusicXML writer, however, currently guards against chords: it raises when it encounters a placement where `chord?` is true, because it only knows how to emit the single derived `placement.pitch` (the highest pitch) and would otherwise silently render the top note alone. It never emits the `<chord/>` element, which is how MusicXML marks a note as sounding simultaneously with the previous note. (The writer's separate `RenderError` guard for placements containing unpitched sounds is out of scope here — it remains until a dedicated percussion-rendering story.)

This story is a prerequisite for BardTheory's staff-notation-view story, which renders compositions via `to_musicxml` → OSMD and requires block chords on the treble staff. The complementary input half is [ABC Chord Input](abc-chord-input.md) — that story gets chords *into* the model; this one gets them *out* to notation.

## Scope

- Replace the writer's chord guard with real rendering: a chord placement emits one `<note>` element per *pitched* sound, first note plain, each subsequent note carrying `<chord/>`, per the MusicXML 4.0 convention. All notes share the placement's rhythmic value.
- Emit chord notes in a deterministic order (low to high) regardless of the insertion order of the placement's `sounds`.
- Leave the writer's `RenderError` guard for unpitched sounds in place — any placement containing an unpitched sound still raises until a percussion-rendering story lands.
- Chords spanning voices are *not* merged — each voice remains its own part; only the pitched sounds of a single placement form a chord.

## Example

```ruby
composition = HeadMusic::Content::Composition.new(name: "Chorale", key_signature: "C major", meter: "4/4")
voice = composition.add_voice(role: "Treble")
voice.place("1:1", :half, %w[C4 E4 G4])
voice.place("1:3", :half, %w[D4 F4 A4])

xml = composition.to_musicxml
# E4 and G4 <note> elements at beat 1 each contain <chord/>; OSMD renders two stacked triads
```

## Acceptance Criteria

- A chord placement emits one `<note>` per pitched sound as a MusicXML chord (`<chord/>` on all but the first note), replacing the writer's raise-on-chord guard
- A composition mixing chords and single notes renders with correct measure durations
- Chord notes emit low to high
- The writer's `RenderError` guard for unpitched sounds is unchanged
- Existing single-line compositions render byte-identically to before (no regression)
- Output validates against the MusicXML 4.0 schema (matching the writer's existing spec approach)
- Rubocop and all specs pass

## Implementation Plan

### Overview

Replace the writer's raise-on-chord guard with a single parametrized note-builder that emits one `<note>` per pitched sound of a placement — the lowest note plain, each higher note carrying `<chord/>` — sorted low→high, sharing the placement's rhythmic value. The single-note and rest paths collapse to the same builder so existing output stays byte-identical. The change is confined to `lib/head_music/notation/music_xml/writer.rb` and its spec.

### Steps

1. **Remove the chord guard and restructure `note_lines`** — `lib/head_music/notation/music_xml/writer.rb:313`
   - Delete the `raise RenderError ... "chords are not yet supported"` line (`:315`). Keep `ensure_pitched_sounds` first — it still raises for any unpitched sound, so every non-rest placement reaching the builder is fully pitched (this is what makes the unpitched-sound guard AC hold unchanged).
   - Nest the loops **components outer, pitches inner** so each tied rhythmic segment emits a complete, contiguous chord block. This ordering is load-bearing: pitches-outer would break `<chord/>` adjacency and produce invalid MusicXML.

   ```ruby
   def note_lines(placement)
     ensure_pitched_sounds(placement)

     components_by_placement[placement].flat_map do |component|
       note_slots(placement).each_with_index.flat_map do |pitch, index|
         note_element_lines(placement, component, pitch: pitch, chord: index.positive?)
       end
     end
   end

   # ensure_pitched_sounds has rejected any unpitched sound, so a sounded
   # placement's pitches are all its sounds; a rest emits one empty slot.
   def note_slots(placement)
     placement.rest? ? [nil] : placement.pitches.sort
   end
   ```

   - `placement.pitches.sort` yields low→high (Pitch is `Comparable`); this is the explicit sort the ordering AC requires — `pitches` is otherwise insertion-ordered. `index.positive?` puts `<chord/>` on all but the lowest note. For a single-pitch placement this is a one-element array at index 0 (`chord: false`), and `pitches.sort.first == placement.pitch` for length 1, preserving today's output exactly.

2. **Parametrize the note builder (rename `component_lines` → `note_element_lines`)** — `writer.rb:330`
   - One builder serves single note, rest, and chord — no second code path to drift.

   ```ruby
   def note_element_lines(placement, component, pitch: nil, chord: false)
     [
       "#{INDENT * 3}<note>",
       *(chord ? ["#{INDENT * 4}<chord/>"] : []),
       *(pitch ? pitch_lines(pitch) : ["#{INDENT * 4}<rest/>"]),
       "#{INDENT * 4}<duration>#{component.duration}</duration>",
       *tie_lines(placement, component),
       "#{INDENT * 4}<type>#{component.type}</type>",
       *Array.new(component.dots) { "#{INDENT * 4}<dot/>" },
       *notation_lines(placement, component),
       "#{INDENT * 3}</note>"
     ]
   end
   ```

   - Byte-identical guarantees: `<chord/>` sits at `INDENT * 4`, first child after `<note>` and **before** `<pitch>` (MusicXML schema requires this order — the one correctness detail that must be right); the `chord ? [...] : []` splat contributes zero lines when false. The rest branch now keys off the passed `pitch:` arg (nil → `<rest/>`) instead of `placement.pitched?`; equivalent because `note_slots` only yields nil for a rest.
   - `tie_lines`/`notation_lines` are unchanged and already per-component + rest-guarded, so each note in a chord (and each tied link) carries its own correctly-matched tie — no chord-specific tie work needed.

3. **Rewrite the two chord specs; add coverage** — `spec/head_music/notation/music_xml/writer_spec.rb`
   - **Flip** the two "raises the chord render error" contexts (`:465-479` three-pitch, `:481-495` two-pitch) from raise-assertions to rendering assertions — they currently pin the removed behavior and will otherwise fail.
   - See Testing Strategy for the exact cases.

4. **Run the checks**

   ```
   bundle exec rspec spec/head_music/notation/music_xml/writer_spec.rb
   bundle exec rubocop -a
   bundle exec rake
   ```

### Design & Notation-Output Considerations

- **`<chord/>` before `<pitch>`, per subsequent note** is the single highest-risk detail — both OSMD and MuseScore mis-parse a `<chord/>` that follows `<pitch>`. The builder above places it correctly.
- **Iterate `placement.pitches`, never reuse `placement.pitch`** (which is `pitches.max`, the top note only). Reusing it would print the top pitch on every chord note — the most likely refactor bug.
- **Low→high order is cosmetic to renderers** (both sort internally) but is the right choice: deterministic, diff-stable, and the conventional bass-up reading order. It must come from the explicit `.sort`, not insertion order.
- **`<stem>`/`<voice>`/`<staff>` omission is fine for v1** single-voice, single-staff block chords, consistent with how single notes already render (the writer emits none today). Consumers default absent voice/staff to 1, and `<chord/>` alone binds the stack. The boundary where `<voice>` stops being optional is multi-voice-per-staff — out of scope, tracked below.
- **Clusters/seconds (C4+D4) and shared-letter accidentals (C4+C#4) are the renderer's job** — each note carries its own `<alter>`; OSMD/MuseScore handle notehead offset and accidental columns automatically. No writer work for v1.

### Accessibility / Semantic Fidelity

Traditional WCAG/keyboard/ARIA do not apply (this emits a string, not a UI). The surface is MusicXML semantic fidelity for Braille-music and MusicXML-reading assistive tools:

- **`<chord/>` on notes sharing a rhythmic value IS the canonical encoding** these tools recognize — a lead `<note>` followed by `<chord/>` siblings with no intervening `<backup>`/`<forward>`. No richer encoding needed.
- **Low→high ordering gives a predictable reading order**, matching Braille music's bass-relative interval convention. Reinforces the explicit-sort requirement.
- **No semantic loss**: each tone keeps full absolute `<pitch>` (step/alter/octave); sharing one `<duration>`/`<type>` is spec-required, not a loss.

### Testing Strategy

"Validates against the MusicXML 4.0 schema" is satisfied here by the repo's actual approach — there is **no** XSD/DTD tooling; do not add a Nokogiri XSD dependency. Verification is: REXML well-formedness via `parse_musicxml` (`spec/support/music_xml_helpers.rb`), XPath structural assertions, and the byte-for-byte golden-document test. (See the AC note: treat "schema validation" as these concrete facts.)

In `spec/head_music/notation/music_xml/writer_spec.rb`, using the existing helpers (`parse_musicxml`, `xpath_count`, `xpath_texts`):

- **Three-pitch chord** `voice.place("1:1", :half, %w[C4 E4 G4])`: `//note` count == 3 for the measure; `xpath_count(document, "//note/chord")` == 2; the lowest note (C4) has no `<chord/>`; all three share `<duration>`.
- **Insertion-order independence**: place `%w[G4 C4 E4]` and assert `xpath_texts(document, "//note/pitch/step")` == `%w[C E G]` (low→high regardless of input order).
- **`<chord/>` element ordering** (child-order, invisible to count-only XPath): assert against the rendered `to_s` that `<chord/>` precedes `<pitch>` — cleanest via a **golden-document fixture** with a chord measure (extend the existing golden test at `:173`, the only mechanism in the suite that catches child-ordering regressions), or a targeted string `include`.
- **Two-pitch boundary**: rewrite the `:481` context to assert emission, pinning `chord?`-true-at-exactly-2.
- **Mixed chords + single notes measure**: `place("1:1", :half, %w[C4 E4 G4]); place("1:3", :half, "D5")` — assert per-note durations and correct note count (measure-duration AC; confirms only the lead note advances the cursor).
- **Tied chord** (if kept in v1 — see Open Questions): a chord with a tied rhythmic value → each tie-link emits a full chord stack with `<chord/>` on the upper notes and ties on every note.
- **Keep green** the unpitched (`:497`) and mixed pitched+unpitched (`:513`) percussion-raise contexts, and the single-line regression contexts (`SPEED_THE_PLOUGH` at `:22`, the golden document at `:173`) — these are the no-regression / byte-identical guard.

### Risks & Open Questions

- **Tied-chord handling in v1 — recommended IN, needs sign-off.** A chord with a tied rhythmic value is reachable through the public `Voice#place` API (`components_by_placement` expands it into multiple tie-link components). The components-outer/pitches-inner nesting handles it correctly with **zero extra code**, and every pitch legitimately shares the link's tie flags. Recommendation: ship the natural handling. The alternative is an explicit `RenderError` guarded by `components_by_placement[placement].length > 1 && placement.chord?` plus a deferral note — but do **not** leave it to silently drop ties. This plan assumes full tied-chord rendering.
- **Byte-identical regression** is the primary technical risk; mitigated by the empty-splat for `chord: false` and by `pitches.sort.first == placement.pitch` for length-1 placements. The existing exact-structure and golden-document specs catch any drift.
- **Duplicate/enharmonic pitches**: `Placement` already dedups exact duplicates via `sounds.uniq`, so an exact unison cannot reach the writer — no writer-side dedup needed. Two distinct spellings at the same height (C#4 + Db4) are a legitimate diminished-second cluster and correctly emit as two notes; order between them is undefined but harmless.
- **Multi-voice-per-staff** is the concrete future trigger where omitting `<voice>`/`<staff>` stops being acceptable. Out of scope for v1; track for the multi-voice story.

## Review

_Reviewed 2026-07-18 at commit `0f1f090` (product-manager + code-reviewer agents). Full suite: 5842 examples, 0 failures, 99.76% line coverage; rubocop 0 offenses._

### Acceptance criteria

- ✅ **Chord emits one `<note>` per pitched sound, `<chord/>` on all but the first, guard removed** — `writer.rb` `note_lines`/`note_element_lines`; specs assert 3 notes, 2 `<chord/>`, none on `note[1]`. No raise-on-chord path remains.
- ✅ **Mixing chords and single notes → correct measure durations** — "measure mixing a chord and a single note" spec: steps `C E G D`, 2 `<chord/>`, durations `2 2 2 2`. Only the lead C4 and D5 advance the cursor → full 4/4 bar.
- ✅ **Chord notes emit low to high** — `note_slots` returns `placement.pitches.sort`; the "placed high to low" spec (`%w[G4 C4 E4]` → `%w[C E G]`) proves the sort, not coincidental input order.
- ✅ **Unpitched-sound guard unchanged** — `ensure_pitched_sounds` runs first and raises on the first non-pitched sound; the mixed pitched+unpitched spec confirms it still fires with the same message.
- ✅ **Single-line output byte-identical** — single note → one slot, `chord: false`, `<chord/>` line omitted; the golden-document test pins the full single-line document byte-for-byte.
- ✅ **Validates against MusicXML 4.0 schema (repo's approach)** — every chord spec parses via REXML + XPath; the golden-string "exact note markup" spec pins `<chord/>`-before-`<pitch>` child order (which count-based XPath cannot see). Caveat, story-acknowledged: no XSD/DTD validator exists in the repo; "schema-valid" is structural, not tool-verified.
- ✅ **Rubocop and all specs pass** — verified; tied-chord case also covered (6 notes / 4 `<chord/>`, 3 tie-starts / 3 tie-stops).

### Code review findings

**Verdict: clean — no blocking or should-fix issues.** Correctness verified on `<chord/>` placement/order, low→high sort, byte-identical single-note/rest paths, tied-chord loop nesting (index resets per tie-link), and guard interaction (no silent empty-slot path). Both new comments explain "why" and earn their place.

Nits (non-blocking, no action taken):

- `note_slots` re-sorts pitches once per tie-link (N times for an N-link tied chord). Negligible; hoisting would churn the diff.
- Enharmonic/duplicate pitches at the same height (C4 + B♯3) render as two chord notes — arguably correct MusicXML, untested. Add a spec only if the domain cares.
- Minor coverage: "correct measure durations" is proven indirectly (duration list + `<chord/>` count) rather than by an explicit sum-to-bar-length assertion. Low risk.
- `note_slots` naming is slightly abstract; the comment carries the meaning.

**Nothing blocks `finish`.**