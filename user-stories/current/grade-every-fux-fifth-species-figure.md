<!--
metadata:
  created_at:   2026-09-21T15:18:56-07:00
  activated_at: 2026-09-21T15:18:56-07:00
  planned_at:
  finished_at:
  updated_at:   2026-09-21T15:18:56-07:00
-->

# Grade Every Fux Fifth-Species Figure

AS a maintainer of the fifth-species guides
I WANT every two-voice fifth-species example in Gradus ad Parnassum graded by
the guides and pinned in the corpus snapshot
SO THAT the embellished-suspension rule is tested against Fux's own lines in
every mode and with the counterpoint below the cantus, not only against one
dorian figure and constructed shapes

Fast follow to
[Embellish Fifth Species Suspensions](../done/embellish-fifth-species-suspensions.md),
which shipped `EmbellishedSuspensionTreatment` with this risk on record: "The
corpus contains no voice with a beat-2 resolution followed by a different
beat-3 pitch, so the stricter rule is untested against real lines beyond the
fixtures." Both it and
[Require the Species Rhythm](../done/require-the-species-rhythm.md) deferred
"the other cantus firmi" to a follow-up. This is that follow-up, narrowed to
the species whose rule is at risk.

## The gap

Every species fixture sits on Fux's D dorian cantus with the counterpoint
above it. Fux wrote fifth species in all six modes, and in most of them twice,
once with the cantus below and once with it above. Mark Gotham's CC0 kern
transcriptions of Gradus enumerate the two-voice fifth-species figures:

| Figure | Mode | Cantus firmus | In the corpus today |
| --- | --- | --- | --- |
| 82 | D dorian | lower | yes |
| 83 | D dorian | upper | no |
| 84a | E phrygian | lower | no |
| 84b | E phrygian | upper | no |
| 85a | F lydian | lower | no |
| 85b | F lydian | upper | no |
| 86a | G mixolydian | lower | no |
| 86b | G mixolydian | upper | no |
| 87a | A aeolian | upper | no |
| 88a | C ionian | lower | no |
| 88b | C ionian | upper | no |

Ten figures are ungraded. Five of them put the counterpoint below the cantus.
Three of Fux's first-species fixtures do that, but none of the fixtures for
the moving species does, so the florid dissonance and suspension rules have
never graded a published bass counterpoint.

The decision the last story took, that an anticipated resolution must still
sound on beat 3, was made on pedagogy and constructed examples. Fux's other
florid lines are the evidence that was missing. If one of them is marked, the
story records why and decides whether the rule or the reading of Fux is wrong.

## Acceptance Criteria

- A fixture for each of figures 83, 84a, 84b, 85a, 85b, 86a, 86b, 87a, 88a,
  and 88b, in Mann's numbering, on Fux's cantus firmus for that mode, with a
  `source` naming the figure. Pitches are taken from the scan and confirmed
  against the kern transcription, as for figures 33, 55, 73, and 82. Any
  disagreement between scan and kern is settled from the scan and noted in the
  story.
- The fixtures are in `PUBLISHED_SOURCES`, so every voice of every figure is
  in `corpus_fitness.json`. Each changed or added snapshot row of an existing
  fixture is explained.
- Every new counterpoint voice is adherent to
  `EmbellishedSuspensionTreatment`, or each mark it earns is listed in the
  story with the figure, bar, and beat, and a decision is recorded: the mark
  stands as a liberty Fux took, or the rule changes and the change is named.
- `guide_species_diagonal_spec` runs over all fifth-species fixtures. The
  fifth-species composite and melody guide grade every one of them at least as
  high as any fixture of another species.
- The counterpoint-below fixtures grade through the fifth-species harmony
  guide without error, and no guideline marks a bass counterpoint for a rule
  that applies only above the cantus.
- `OnePerBar`, `TwoPerBar`, and `FourPerBar` count middle bars over the voice's
  own span, as `SustainAcrossBarlines` does, so a solo voice no longer passes
  them vacuously. Both earlier stories noted this as a small follow-up.
- Locale strings, `english_strings.yml`, and the guide-string canaries are
  unchanged unless a rule changes, in which case the changed sentence is a
  decision recorded here.

## Notes

- Kern sources: `https://raw.githubusercontent.com/MarkGotham/species/HEAD/1x1/gap_NNN.krn`
  (`gap_083.krn`, `gap_084a.krn`, and so on). Each carries a header naming the
  figure, species, modal final, and which voice is the cantus. The scan is
  `Fux_Gradus.pdf` in `~/Documents`; render at 400 dpi or better with
  `pdftoppm` to read ties and accidentals.
- The ABC parser accepts `K:Ephr`, `K:Flyd`, `K:Gmix`, `K:Aaeo`, and `K:Cion`
  (verified 2026-09-21). `dorian_species_abc` should become a general helper
  that takes the key and the cantus, with the dorian one delegating to it.
- Fux's cantus firmi for the other modes are already in `spec_helper.rb` as
  `fux_cantus_firmus_examples`; use the same pitches so the two corpora agree.
- The fixtures name voices by role (`V:cantus firmus`, `V:counterpoint`), so
  a counterpoint below the cantus is only lower pitches in the counterpoint
  voice. The guidelines that branch on `bass_voice?`, such as
  `StartOnPerfectConsonance`, already meet a bass counterpoint in the
  first-species fixtures; the florid guidelines do not.
- Each two-voice fixture adds 60 snapshot rows, so expect about 600 new rows
  in `corpus_fitness.json`. That diff is mechanical; the rows to read are the
  ones for the existing fixtures, which should not move.
- Second, third, and fourth species in the other modes are not in this story.
  Their rhythm guidelines already separate the species on the dorian diagonal
  and were not changed by the last story, so those fixtures would cost the
  same transcription per figure and answer no open question. They can follow
  once the fifth-species figures show whether the other modes surprise us.
- The raised leading tone Fux writes in the penultimate bar is an accidental
  in the ABC, as `^c` is in figure 82. Whatever `Diatonic` charges for it is
  already pinned by figure 82, so it should not move the diagonal.

## Implementation Plan

[to be filled in by /stories plan]
