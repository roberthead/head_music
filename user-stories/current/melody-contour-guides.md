<!--
metadata:
  created_at:   2026-07-05T13:55:34-07:00
  activated_at: 2026-07-05T16:12:05-07:00
  planned_at:   2026-07-05T16:28:11-07:00
  finished_at:
  updated_at:   2026-07-05T16:33:40-07:00
-->

# Story: Melody Contour Guides

## Summary

AS a composer or student using HeadMusic to evaluate melodies
I WANT style guides that assess whether a diatonic melody follows a specified contour (ascending, descending, arch, valley, wave, or static)
SO THAT I can shape melodic writing toward an intended overall gesture and get actionable feedback when the melody doesn't match

## Acceptance Criteria

- A configurable guideline `HeadMusic::Style::Guidelines::Contoured` exists, configured via `Contoured.with(:arch)` (and the other five contour keys)
- `Contoured.with` raises an error for a key not in `CONTOURS`, so a typo fails at guide-definition time
- A melody matching the configured contour receives no marks (adherent, fitness 1.0)
- A melody not matching the configured contour receives a single mark spanning all notes (one violation, one penalty — no per-note compounding) with the message "Write a melody with the {contour} contour."
- Contour predicates are trend-based, not strictly monotonic — local direction changes are allowed; existing guidelines (e.g., `ModerateDirectionChanges`) already police local motion:
  - **Ascending**: the lowest pitch occurs at (or tied with) the first note and the highest pitch at the last note — the line departs its floor and arrives at its ceiling
  - **Descending**: mirror of ascending — highest pitch at the first note, lowest pitch at the last note
  - **Arch**: a single climax (highest pitch) in the interior (not the first or last note), with a net rise before it and a net fall after it
  - **Valley**: mirror of arch — a single nadir (lowest pitch) in the interior, with a net fall before it and a net rise after it
  - **Wave**: at least 3 direction changes at the trend level (rise–fall–rise or fall–rise–fall), distinguishing repeated undulation from a single-turn arch or valley
  - **Static**: total range no larger than a major third, and the endpoints must not sit at the extremes in a way that implies another contour (must not start at the lowest pitch and end at the highest, nor start at the highest and end at the lowest)
- Six guides exist as subclasses of `HeadMusic::Style::Guides::DiatonicMelody` — `AscendingContourMelody`, `DescendingContourMelody`, `ArchContourMelody`, `ValleyContourMelody`, `WaveContourMelody`, `StaticContourMelody` — each appending the appropriately configured `Contoured` guideline to the inherited RULESET
- The arch predicate complements rather than duplicates `ConsonantClimax` (contour judges shape; climax consonance/uniqueness stays with `ConsonantClimax` — no double-flagging of the same defect)
- Specs cover adherent and non-adherent melodies for each contour (using ABC notation per the existing spec convention), coverage stays ≥ 90%, rubocop clean

## Notes

- Sketch in progress at `lib/head_music/style/guidelines/contoured.rb` (a previously drafted `arch_contour_melody.rb` stub was deleted; all six guide files are created fresh)
- Design decision (2026-07-05): configurability lives at the guideline layer (matching the `MinimumNotes.with` / `LargeLeaps.with` pattern); guides remain named classes because guides are the gem's pedagogical vocabulary and contour is a single closed axis with six values — revisit guide-level `.with` only if a second orthogonal configuration axis appears
- Guide naming follows the existing stub's convention: `{Contour}ContourMelody`
- Mark semantics: `Annotation#fitness` is the product of mark fitnesses, so one spanning mark applies the penalty once; per-note marks would compound `PENALTY_FACTOR` per note and crush fitness on long melodies
- `references/third-species-counterpoint.md:310` is the only contour mention in the references ("The line should have an overall arch or wave shape")

## Implementation Plan

### Overview

Complete the existing sketch at `lib/head_music/style/guidelines/contoured.rb` (six empty predicates, validation, guards), register it in `lib/head_music.rb`, then add six two-line guide classes subclassing `HeadMusic::Style::Guides::DiatonicMelody` that append `Contoured.with(:contour)` to the inherited RULESET. All predicate math uses existing Comparable APIs (`Pitch#<=>` via midi note number, `DiatonicInterval#<=>` by semitones); no changes to existing classes, no data model, no locale entries.

### Steps

1. **Finish the `Contoured` guideline**
   - Replace `contour_key.to_s.underscore.to_sym` with `contour_key.to_s.downcase.to_sym` — `String#underscore` only works here because ActiveSupport inflections load transitively (`lib/head_music.rb` requires only `module/delegation`, `string/access`, `integer/inflections`); do not depend on that.
   - Validate in `self.with` so a typo raises at require time (RULESET constants evaluate in guide class bodies at load), using the gem's enum-validation precedent (`lib/head_music/rudiment/mode.rb:32`):

     ```ruby
     def self.with(contour_key)
       contour = contour_key.to_s.downcase.to_sym
       unless CONTOURS.include?(contour)
         raise ArgumentError, "Contour must be one of: #{CONTOURS.join(", ")} (got #{contour_key.inspect})"
       end
       super(contour: contour)
     end
     ```

   - Also validate in the private `contour` reader (same guard) so `Contoured.new(voice, contour: :bogus)` — which bypasses `.with` — fails with a clear error instead of a `NoMethodError` from `send("#{contour}?")`. After validation, the `send` dispatch is safe and idiomatic; no case/when needed.
   - Guard `marks`: `return if notes.empty? || matches_contour?` — matches the "no notes is adherent" convention (see `spec/head_music/style/guidelines/moderate_direction_changes_spec.rb`) and prevents `DiatonicInterval.new(nil, nil)` via `range`.
   - Implement the six predicates and the shared `trend_directions` helper (next section). Keep the sketched `message` and `Mark.for_all(notes)` — `for_all` returns one spanning mark, so a violation costs exactly one `HeadMusic::PENALTY_FACTOR`.
   - Files: `lib/head_music/style/guidelines/contoured.rb`

2. **Require the guideline**
   - Insert `require "head_music/style/guidelines/contoured"` alphabetically between `consonant_downbeats` (line 161) and `diatonic` (line 162).
   - Files: `lib/head_music.rb`

3. **Create the six guide classes**
   - Each is a thin subclass using the explicit splat pattern (matching `DiatonicMelody`'s own composition style); avoid the self-shadowing `RULESET = [*RULESET, ...]` form:

     ```ruby
     # A free diatonic melody with an arch contour (interior climax).
     class HeadMusic::Style::Guides::ArchContourMelody < HeadMusic::Style::Guides::DiatonicMelody
       RULESET = [
         *HeadMusic::Style::Guides::DiatonicMelody::RULESET,
         HeadMusic::Style::Guidelines::Contoured.with(:arch)
       ].freeze
     end
     ```

   - No intermediate `ContourMelody` base class — six two-line frozen constants are not duplication worth an abstraction.
   - Files: `lib/head_music/style/guides/arch_contour_melody.rb`, `ascending_contour_melody.rb`, `descending_contour_melody.rb`, `static_contour_melody.rb`, `valley_contour_melody.rb`, `wave_contour_melody.rb`

4. **Require the guides**
   - Insert the six requires immediately after `require "head_music/style/guides/diatonic_melody"` (line 221), alphabetized among themselves (arch, ascending, descending, static, valley, wave). The guides block is dependency-ordered — they must load after their superclass (and after `guidelines/contoured`), so they cannot be merged into strict whole-block alphabetical order.
   - Files: `lib/head_music.rb`

5. **Specs** (detail under Testing Strategy)
   - Files: `spec/head_music/style/guidelines/contoured_spec.rb` plus six specs under `spec/head_music/style/guides/`

6. **Polish**
   - `bundle exec rubocop -a`, then `bundle exec rake` (tests + coverage gate at 90%).

### Contour Predicate Algorithms

All predicates operate on delegated voice methods; `notes.empty?` never reaches them (guarded in `marks`). Shared helpers (private, memoized per the gem's instance-ivar style):

```ruby
TREND_REVERSAL_SEMITONES = 3 # a trend reversal must exceed a whole step

def pitch_numbers
  @pitch_numbers ||= notes.map { |note| note.pitch.midi_note_number }
end
```

- **ascending?** — `first_note.pitch == lowest_pitch && last_note.pitch == highest_pitch`. Comparing pitches (not membership in `highest_notes`) handles tied extremes for free: a later recurrence of the floor pitch still satisfies "at (or tied with) the first note". Degenerate all-same-pitch melodies pass; length policing belongs to `MinimumNotes.with(5)` already in the RULESET.

- **descending?** — mirror: `first_note.pitch == highest_pitch && last_note.pitch == lowest_pitch`.

- **arch?** — `notes.length >= 3 && first_note.pitch < highest_pitch && last_note.pitch < highest_pitch`. Because the climax is by definition the maximum, "net rise before, net fall after" is exactly equivalent to "both endpoints sit below the climax pitch"; the length guard ensures an interior exists. Deliberately does **not** require a unique climax — see the double-flagging resolution below.

- **valley?** — mirror: `notes.length >= 3 && first_note.pitch > lowest_pitch && last_note.pitch > lowest_pitch`.

- **wave?** — `trend_directions.length >= 3`, where `trend_directions` is built by a single-pass zigzag walk: a trend reversal is confirmed only when the melody retraces at least `TREND_REVERSAL_SEMITONES` (3, a minor third) from the running extreme of the current trend. Justification: steps (1–2 semitones) are the unit of local motion already policed by `ModerateDirectionChanges`/`MostlyConjunct`, so stepwise neighbor-note undulation (E–F–E) never registers as a trend change.

  ```ruby
  def trend_directions
    @trend_directions ||= begin
      directions = []
      direction = nil
      high = low = pitch_numbers.first
      extreme = nil
      pitch_numbers.drop(1).each do |number|
        case direction
        when nil # no trend confirmed yet
          if number - low >= TREND_REVERSAL_SEMITONES
            direction = :ascending
            extreme = number
            directions << direction
          elsif high - number >= TREND_REVERSAL_SEMITONES
            direction = :descending
            extreme = number
            directions << direction
          else
            high = [high, number].max
            low = [low, number].min
          end
        when :ascending
          if number > extreme
            extreme = number
          elsif extreme - number >= TREND_REVERSAL_SEMITONES
            direction = :descending
            extreme = number
            directions << direction
          end
        when :descending
          if number < extreme
            extreme = number
          elsif number - extreme >= TREND_REVERSAL_SEMITONES
            direction = :ascending
            extreme = number
            directions << direction
          end
        end
      end
      directions
    end
  end
  ```

  `directions` alternates by construction, so length ≥ 3 means rise–fall–rise or fall–rise–fall at the trend level (three trend legs), distinguishing a wave from a single-turn arch/valley (two legs). Hand-verified: C D E D C D E → `[asc, desc, asc]` (wave); C D E G E D C → `[asc, desc]` (arch, not wave); C D C D C → `[]` (sub-threshold undulation). Repeated pitches are inert.

- **static?** — `range <= HeadMusic::Analysis::DiatonicInterval.get(:major_third) && !directional_endpoints?`. `DiatonicInterval#<=>` coerces symbols via `.get` and compares by semitones, so this is inclusive at exactly M3 per the "no larger than" wording. The endpoint exclusion:

  ```ruby
  def directional_endpoints?
    highest_pitch > lowest_pitch &&
      ((first_note.pitch == lowest_pitch && last_note.pitch == highest_pitch) ||
        (first_note.pitch == highest_pitch && last_note.pitch == lowest_pitch))
  end
  ```

  The `highest_pitch > lowest_pitch` guard is load-bearing: without it, an all-same-pitch melody (first == lowest and last == highest simultaneously) would absurdly fail static.

**Arch vs. ConsonantClimax (no double-flagging).** `ConsonantClimax` already penalizes climax multiplicity (allowing once, or twice with a step between) and consonance. If `arch?` also demanded a unique climax, a melody like C D G E G E D C would collect two penalties for the single defect "repeated climax". Resolution: `arch?` requires an *interior* climax only; climax uniqueness and consonance remain solely ConsonantClimax's job. The AC's "single climax" is satisfied as a single climax *pitch level* located in the interior. A spec proves the split (below). The predicates are intentionally not mutually exclusive across guides (e.g., a wavy line can also satisfy `arch?`); each guide checks only its configured contour, so overlap is leniency, not defect — the endpoint-exclusivity rule applies to `static?` alone, as specified.

### Messages & i18n

- Style-guideline messages are plain English throughout — `MESSAGE` constants or interpolated `def message` overrides (`MinimumNotes`: "Write at least #{minimum.humanize} notes."); none are translated in `lib/head_music/locales/`. The sketch's interpolated `"Write a melody with the #{contour} contour."` matches both the mechanism and the "Write..." register exactly. Keep it; adding i18n for this one message would break convention — defer as future work across all guideline messages.
- The `ArgumentError` message must enumerate the valid keys (as in the snippet above) so a typo tells the user what is allowed — matches the `mode.rb` precedent.
- Optional deferred polish: indefinite-article variation ("an arch contour" vs "the ascending contour"), implementable via the `SingableRange::VOWEL_SOUND_ORDINALS` pattern; the AC pins the current template, so ship as written.

### Testing Strategy

**`spec/head_music/style/guidelines/contoured_spec.rb`** — construct melodies with `HeadMusic::Notation::ABC.parse` heredocs (headers `X:1 / M:4/4 / L:1/4 / K:C`; ABC `C` = C4, `c` = C5), `voice = composition.voices.first`, subject `described_class.with(:contour).new(voice)`. Test only the public surface (`fitness`, `marks`, `message`, `be_adherent`) — never the private predicates, per gem convention.

- `.with`: returns `Annotation::Configured` with `options == {contour: :arch}`; accepts a string key (`"Arch"`); `expect { described_class.with(:zigzag) }.to raise_error(ArgumentError, /zigzag/)`.
- Per contour, adherent and non-adherent contexts (each melody ≥ 5 notes):
  - ascending: adherent `CDED|EFEF|G4|`; tied-floor adherent `CDCE|FGA2|`; non-adherent `CDEG|EDC2|`
  - descending: adherent `GFEF|EDED|C4|`; non-adherent `CDED|EFG2|`
  - arch: adherent `CDEG|EDC2|`; repeated-interior-climax adherent `CDGE|GEDC|` — in the same context assert `ConsonantClimax.new(voice)` is *not* adherent (the no-double-flagging proof); non-adherent `CDEF|G4|` (climax at last note)
  - valley: adherent `GFEC|DEFG|`; non-adherent `GFED|C4|`
  - wave: adherent `CDED|CDE2|` (m3-sized legs); non-adherent `CDEG|EDC2|` (single turn); non-adherent `CDCD|C4|` (whole-step undulation below threshold)
  - static: adherent `EDEF|EFED|E4|` (range m3, neutral endpoints); adherent all-same-pitch `EEEE|E4|`; non-adherent `CDEF|G4|` (range P5); non-adherent `CDCD|E4|` (range exactly M3 but endpoints imply ascending)
- Violation assertions: `fitness == HeadMusic::PENALTY_FACTOR` and exactly one mark (single spanning mark, no per-note compounding); `message` equals the exact template output.
- Edge cases: empty voice adherent for every contour; single-note melody adherent for ascending/descending/static and non-adherent for arch/valley/wave (no interior / no trend legs exist) — flagging both length (`MinimumNotes`) and contour is two distinct defects, not double-flagging; one melody containing a rest to confirm trend computation is rest-transparent (`notes` excludes rests).

**Six guide specs** — `spec/head_music/style/guides/{arch,ascending,descending,static,valley,wave}_contour_melody_spec.rb`, mirroring `diatonic_melody_spec.rb` conventions (`configured(...)` helper):

- RULESET includes everything in `DiatonicMelody::RULESET` (object identity holds via the splat) plus `configured(HeadMusic::Style::Guidelines::Contoured, contour: :arch)` etc.
- One integration pair per guide via `HeadMusic::Style::Analysis.new(described_class, voice)`: adherent melody → `analysis.messages` excludes the contour message; non-adherent → includes it. Assert message presence/absence rather than overall adherence so unrelated guidelines (ConsonantClimax, ModerateDirectionChanges) cannot break the test — note a strictly monotonic 6+ note line adherent to AscendingContour will still be flagged by ModerateDirectionChanges at the guide level, which is coherent with "trend-based" but worth one demonstrating spec (undulating-yet-ascending adherent melody).

### Risks & Open Questions

- **Wave count semantics** (confirmed 2026-07-05): wave = ≥ 3 trend legs (rise–fall–rise), matching the AC's examples.
- **Trend-reversal threshold** (confirmed 2026-07-05): `TREND_REVERSAL_SEMITONES = 3` (a reversal must exceed a whole step); a hardcoded constant in the style of `ModerateDirectionChanges`, tunable without structural change. Accepted consequence: a melody undulating purely by whole steps registers zero trend legs and fails `wave?` (it will typically satisfy `static?` instead).
- **Arch "single climax" reading** (confirmed 2026-07-05): "single climax" means a single climax pitch level located in the interior; multiplicity stays with ConsonantClimax (this is what makes the no-double-flagging criterion satisfiable). The spec `CDGE|GEDC|` pins the behavior.
- **Semitone-based comparisons**: `range <= :major_third` compares by semitones, so a diminished fourth (4 semitones) counts as static-sized; enharmonic edge cases (B#3 vs C4 extremes) are theoretically ambiguous under spelling-based `Pitch#==` but unrealistic for diatonic melodies. No mitigation needed.
- **Degenerate pass-through**: an all-repeated-pitch melody passes `ascending?`, `descending?`, and `static?`; nothing in DiatonicMelody's RULESET flags it (no `AlwaysMove`). Accepted as out of scope for contour.
- **Deferred by scope**: contour of subphrases; configurable static-range threshold and wave leg count (constants only); i18n of guideline messages; a contour-*detection* API ("which contour is this melody?"); wiring contour guides into species RULESETs; message article grammar ("an arch contour").
