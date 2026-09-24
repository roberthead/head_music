# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Four counterpoint stories, [Require the Species Rhythm](https://github.com/roberthead/head_music/tree/main/user-stories/done/require-the-species-rhythm.md), [Embellish Fifth Species Suspensions](https://github.com/roberthead/head_music/tree/main/user-stories/done/embellish-fifth-species-suspensions.md), [Grade Every Fux Fifth-Species Figure](https://github.com/roberthead/head_music/tree/main/user-stories/done/grade-every-fux-fifth-species-figure.md), and [Fifth Species Guide Improvements](https://github.com/roberthead/head_music/tree/main/user-stories/done/fifth-species-guide-improvements.md). Every species guide now insists on the rhythm its species teaches, fifth species accepts the decorated suspensions Fux allows and requires the mixture that defines it, and every two-voice fifth-species figure in Gradus is graded and pinned. Fux's lines are graded as evidence, not as an oracle: where one of them outruns a rule that every other source keeps, the mark stands and is recorded as his liberty. Two grades move, both in the direction the pedagogy says they should, and the count guidelines now grade the solo and cantus-firmus lines they had passed on nothing; everything else is additive, including ties across bar lines in ABC.

### Added

- **`Style::Guidelines::MixSpeciesTextures`, strong and primary in `FifthSpeciesMelody` in place of `MixedRhythmicValues`.** Fifth species is the free mixture of the other four, and Salzer and Schachter allow "two, or at most, two-and-a-half measures of a single note value" (*Counterpoint in Composition*, pp. 101-102). Each bar from the voice's first to the one before its last is classified by the texture it shows: a note that fills the bar, halves, quarters and eighth pairs, or a ligature entered by tie. Every bar of a run of more than two bars in one texture is marked, configurable through `maximum_run:`. A bar that mixes textures is florid and an empty bar is left to the rest rules; either ends a run. It is strong although a proportion usually makes a guideline weak, because one texture running on decides whether a line is fifth species at all. All twelve Fux fifth-species counterpoints are adherent. Fux's fourth-species figure 73 falls from 0.929 to 0.826 on the `fifth_species` composite, its eight ligature bars marked in two runs on either side of an untied bar; his second- and third-species figures fall to 0.815 and 0.795, and every first-species counterpoint to between 0.59 and 0.63, and the species diagonal spec now asserts that every other species grades 0.85 or below there. In the pinned corpus, 173 rows move, all on `fifth_species_melody` and the `fifth_species` composite: every one-texture voice falls, including every cantus firmus, every first-species counterpoint, the solo and against-empty lines, and the cantus voices of the species fixtures; the triple-meter cantus counts too, since a dotted whole that fills its bar is the whole-note texture. Two three-bar solo lines rise and lose their one message, because two body bars cannot hold an over-long run, where the old rule marked any line with fewer than three durations. No other message or item count moves, and no harmony grade moves.

- **`Style::Guidelines::PreferLongBeforeShort`, secondary and weak in `FifthSpeciesMelody`.** A bar that opens with two quarters and closes with a longer note that does not tie forward is marked: Salzer and Schachter call that note "a static point" that "blocks the flow from the two quarters rather than channeling it into the following measure" (*Counterpoint in Composition*, p. 103), and Fux marks the shape N.B. in figure 88 bar 5 and offers figure 89 as better. A longer note that ties over the bar line is exempt, as is a bar entered by a tie. It is weak because Fux calls the alternative better rather than calling his own line wrong. Figure 88a is the only voice marked and falls from 1.000 to 0.995 on `fifth_species_melody` and to 0.997 on the `fifth_species` composite. The new item adds one to the item count of every gated row of those two guides, 250 in the pinned corpus; 176 of them rise by at most 0.005 because the secondary tier's weight is shared among one more item, and 72 move in item count only.

- **Every two-voice fifth-species figure of Gradus as a spec fixture.** Figures 83 through 88 in Mann's numbering join figure 82 in `spec/spec_helper.rb`: each of the six modes once with the counterpoint above the cantus firmus and once below, read from the scan and confirmed against the kern transcriptions in MarkGotham/species, except figure 87's upper counterpoint, which has no kern and is read from the scan alone. The kern drops the tie from bar 11 into bar 12 of figure 86a at a system break; the fixture follows the scan. `species_abc` takes an ABC key and draws the cantus firmus from `FUX_CANTUS_FIRMUS_ABC`, so a species fixture can sit on any of Fux's six cantus firmi. The pinned corpus gains 660 rows and moves none. Every new counterpoint clears both primary items of `FifthSpeciesHarmony` except figure 85b, whose suspension from bar 1 resolves as an eighth on beat 2 of bar 2 and has moved on by beat 3. No source but Fux sanctions that shape, so `EmbellishedSuspensionTreatment` keeps marking it, a spec context pins the mark, and the species diagonal spec excludes that one cell by name through a map of liberties rather than by loosening the comparison. It grades 0.916 on the `fifth_species` composite; the other eleven grade between 0.953 and 1.000.

- **`Style::Guidelines::SustainAcrossBarlines`, primary in `FourthSpeciesMelody`.** A bar is sustained when the note sounding at its downbeat began before it, so a whole note placed on beat three and a half tied to a half count the same. A quarter of the middle bars may break the syncopation, as Fux allows where no ligature will fit; past that, every bar entered without a ligature is marked. It is judged over the voice's own bars rather than the cantus firmus's, so a solo line is held to it too. `OneToOneWithTies` stays beside it: that rule bounds how many notes sound against each cantus note, and a plain first-species line passed it, which is why a first-species line graded 0.988 on the fourth-species composite.

- **`Style::Guidelines::EmbellishedSuspensionTreatment`, primary in `FifthSpeciesHarmony` in place of `SuspensionTreatment`.** Fifth species lets the space between a suspension and its resolution be decorated. The resolution is still the note sounding halfway through the bar, on its second strong beat: a descending step from the suspended pitch and consonant there, whether attacked on that beat or anticipated on beat two and held. That accepts all five shapes the fifth-species reference describes — the anticipated resolution, the anticipated resolution with an eighth-note lower neighbor, the escape tone, the consonant leap, and Fux's delayed resolution — and still marks an unprepared suspension, one left by leap, one resolving upward, one first resolving on beat four, one held through the bar, and an anticipation abandoned on beat three. What is attacked between the suspension and that beat is `FloridDissonanceTreatment`'s to judge, so a dissonant leapt-to quarter is marked once, not twice. The slot presupposes a suspension over a downbeat whose cantus note lasts to that beat; a cantus note attacked off the downbeat or gone before it, and a meter with no second strong beat, get the strict rule. Fourth species keeps `SuspensionTreatment` unchanged.

- **Ties across bar lines in ABC.** `Notation::ABC.parse` now carries a tie over a bar line into one placement whose rhythmic value keeps the authored split, where it used to raise "Ties across barlines are not yet supported"; the tie carries its accidental across the line, so `^D2-|D2` is one D-sharp. A tied note is kept pending across a volta bracket as well. The writer does the inverse: a placement that sounds across a bar line is written as one note per bar, tied, so a flow of fourth-species ligatures writes back as valid ABC and re-parses to the same placements. In-bar tie chains still collapse to one multiplier on output.

- **Fux's diminution species as spec fixtures.** `spec/spec_helper.rb` carries Mann's figures 33, 55, 73, and 82 — second, third, fourth, and fifth species above the D dorian cantus firmus — checked against the scan and against the kern transcriptions in MarkGotham/species, plus a constructed triple-meter third-species line labeled as such. They join the pinned corpus, and a new species diagonal spec asserts that every species composite and melody guide grades its own species' fixture at least as high as any other species' fixture.

### Changed

- **`Diatonic` accepts the accidentals the modes require.** Salzer and Schachter (*Counterpoint in Composition*, pp. 9-10 and 20) name four, and the guideline now exempts exactly those: a raised seventh that steps up to the tonic anywhere in the line, which subsumes the old exemption for a sharpened penultimate note; a raised sixth that steps up to a raised seventh; the lowered fourth in lydian; and the lowered sixth in dorian or lowered third in mixolydian, approached from above and left downward. Phrygian gets no B-flat. Every Fux fifth-species counterpoint now clears `Diatonic`: figure 82's B-flat in `d c _B G`, figure 86a's mid-line F-sharp, and the five lydian B-flats of 85a and 85b. The same exemption clears the descending B-flat of Fux's fourth-species figure 73 and two of the five B-flats in his third-species figure 55; the other three are not in descent and stay marked, as do the F-sharps of the cantus firmus written with chromatic notes added. In the pinned corpus, those six counterpoints rise under the 23 guides that carry `Diatonic`, 138 rows, by at most 0.002 on a species composite, where `Diatonic` is secondary; no row falls.

- **`StepOutOfUnison` exempts the opening note and a unison tied over the bar line.** Salzer and Schachter permit a unison "if tied over or followed by stepwise motion" (*Counterpoint in Composition*, p. 106), and the opening unison belongs to the rules for beginnings (p. 40). The rule stays in every moving species, which is where they state it. Fux's figures 83 and 86b, whose opening unisons are left by leap, now clear it; the interior unisons left by leap in figures 82 (twice), 84a, 85a, and 86a keep their marks as his liberties, pinned by name in the spec. In the pinned corpus, 120 rows rise, ten voices under the twelve guides that carry the rule: those two counterpoints, the cantus firmus of figures 83, 86b, and 87a, of Fux's third-species figure, and of two first-species figures, each of which opens in unison with its counterpoint, and the two against-cantus lines. No row falls.

- **`AlwaysMove` accepts the anticipated resolution.** A quarter on beat 2 that repeats as the beat-3 resolution of a suspension held from the previous bar, the shape Salzer and Schachter name "anticipation of tone of resolution" (*Counterpoint in Composition*, p. 104), is no longer marked as a repeated note, whether or not the resolution ties forward. A repeated half, a repeated quarter with no suspension before it, and a quarter approached from below stay marked, so figure 85b keeps its mark in bar 9. Fux's figures 86a, 87 upper, 87a, and 88b lose their one `AlwaysMove` mark and rise under every guide that grades a counterpoint with it, 56 rows in the pinned corpus, each one message fewer; nothing else moves.

- **`NoteCountPerBar` judges the voice's own bars.** `OnePerBar`, `TwoPerBar`, `ThreePerBar`, and `FourPerBar` borrowed the companion voice's note list to decide which bars to inspect, so a voice with no companion passed on nothing, a bar was charged once per companion note when the companion was florid, and an empty bar's mark landed on the companion's note. They now judge the bars between the voice's own first and last notes, as `SustainAcrossBarlines` does, mark an empty bar as a span with no placements, and leave an empty voice to the minimum-notes gate. In the pinned corpus, 362 rows move, all under the first- through third-species guides: solo lines and lines against an empty companion are now marked; every cantus firmus graded on its own, whose companion voice is empty, is now marked by the second- and third-species count rules; the cantus voices of the species fixtures rise by a few thousandths where a florid companion had charged them once per note; and a counterpoint shorter than its cantus firmus is no longer charged for bars it never wrote. No harmony grade moves, and no counterpoint that runs the length of its cantus firmus moves.

- **A first-species line now grades materially lower against fourth species.** Across the ten valid Fux first-species fixtures, `fourth_species_melody` falls from 0.986 to between 0.68 and 0.71 and the `fourth_species` composite from 0.988 to between 0.80 and 0.84, while Fux's own fourth-species line grades 0.999 on the melody guide. Second, third, triple-meter, and fifth species already discounted a first-species line by a quarter through their melody primaries and are unchanged. The harmony guides deliberately do not check rhythm; `SpeciesHarmony` records that the melody guide's primary tier is where the species' rhythm is required.

- **Fux's fifth-species example now grades as fifth species.** Figure 82 rises from 0.819 to 0.937 on `fifth_species_harmony` and from 0.891 to 0.953 on the `fifth_species` composite, above his fourth-species line's 0.929 there, because its bar 9 suspension, resolved through an interposed consonant third, is no longer marked. No other corpus grade moves.

- **`FloridDissonanceTreatment`'s strings no longer promise to prepare and resolve tied suspensions.** The guideline judges each note at its attack, so a held-over suspension never reached it and the branch that claimed to handle one was unreachable; the branch is deleted and the English and British sentences now end at "on a weak beat". No grade changes.

### Removed

- **`Style::Guidelines::MixedRhythmicValues`.** It asked only for three distinct durations and placed one mark when a line had fewer, which is why Fux's fourth-species line graded within 0.024 of his fifth-species line on the `fifth_species` composite. `MixSpeciesTextures` replaces it; no other guide used it.

### Fixed

- **ABC repeat and volta tagging for a note that outlasts its bar.** The parser counted completed bars from where the last note started, so a note longer than its bar, or one now tied across the line, shifted every following repeat flag by a bar. Bars are counted from where the last note ends.

## [21.1.0] - 2026-09-10

The [organizing content](https://github.com/roberthead/head_music/tree/main/user-stories/epics/organizing-content.md) epic's second story. 21.0.0 separated the document from the music; this separates the music from what it *is* and from how it is *shown*. A flow may now cite a `Work` — the piece, with its catalog number and its people — while a project credits whoever made *this version* of it, so Bach is credited for the work and Segovia for the arrangement. A `Layout` is a view of a project: which flows, which players, concert or written pitch, under what title. Two layouts over one project — a transposed score and a flute part book — are two documents from one body of music.

**This is a minor release.** Everything below is additive: no public method changes signature or return type, `Flow#composer` is still a `String` or nil, `Flow.new`'s keywords are only extended, every writer's new option defaults to what it did before, and `Flow#to_abc`, `#to_lilypond`, and `#to_musicxml` are byte-identical for every flow that existed in 21.0.0. The serialization schema stays at 4 (see the last entry). The one behavioral change is the contour grading under Changed, which alters no signature but does regrade some melodies. A consumer upgrades by upgrading.

### Added

- **`HeadMusic::Content::Work`, with `Person`, `Credit`, `Credits`, and `Role`.** A work is the catalog identity of a composition — a title, a catalog number, a year, and its people — independent of any one notated version of it. A `Flow` may cite one, or cite none, and flows in one project may cite different works: a sonata is one project whose four flows cite one work, a fake book is one project whose eighty flows cite eighty, and a counterpoint exercise cites none. Putting the identity on the project instead would have made the model lie in exactly the cases this gem is most used for.

  **Credits are constrained by the level they attach to**, so the model cannot record a publisher as having composed the music:

  | Level | Roles |
  |---|---|
  | `Work` | composer, songwriter, lyricist, librettist |
  | `Project` | arranger, transcriber, orchestrator, reconstructor |
  | `Publication` | author, editor, engraver, publisher |

  `Credits.new(level)` is the single place that constraint is enforced — `credits.add(person, :arranger)` on a work raises `ArgumentError` naming both levels — and `Credit` itself is level-agnostic. `Role` is `Named` and translated like the rest of the gem's vocabulary, but unlike a rudiment getter an unrecognized identifier raises rather than minting a role: the twelve are the whole vocabulary. `Person` is one identity rather than one spelling of a name, requiring a full name, with an optional sort name and independently optional birth and death years; `Work`, `Person`, `Credit`, and `Credits` are all frozen values, so two flows citing the same work hold two equal objects and `project.works` deduplicates them.

- **`Flow#work` and `Flow#source`, and `Project#credits`.** `Flow#composer` now answers the cited work's composer and falls back to the authored string, which is what the ABC `C:` and LilyPond `composer =` readers fill with text like "Trad." or "arr. J. Smith" — not a person, and never minting a work. A work with no composer credit falls through to the string too, so a lyricist-only work still prints the name it was authored with, and `Flow#to_h` writes the derived string, so **every existing document renders exactly as it did**. `origin` stays a plain string: ABC's `O:` is geographic provenance, which nothing at the work level holds. `Project#add_credit(person, role)` records this version's people.

- **`HeadMusic::Content::Publication`**, the edition a flow cites as its `source` — the book, treatise, or score, with its own credits, distinct from the work it publishes. `CantusFirmus::Source` is now a `Publication` carrying a catalog key: `Source.get`, `.all`, `.keys`, `#publication_name`, `#publication_edition`, `#author_names`, `#abbreviation`, and `#notes` are all unchanged, and their specs pass unedited. `Example#to_flow` cites its source on the flow it builds, so the citation is a fact about the music rather than only about the catalog, and a serialized source round-trips through its key back into the catalog entry itself. `author` joins the publication-level roles because these sources are treatises, whose people are authors rather than editors.

- **`HeadMusic::Content::Layout`.** A layout selects flows and players (`nil` means all of them), renders in concert or written pitch, and titles the document with `title_override` — which changes what is displayed without touching `work.title` or `flow.name`. A selected flow that no selected player has a part in is skipped rather than rendered empty: a flute part book has two movements, not a silent third. A layout refuses a flow or player its project does not hold, so a stray selection fails when it is made rather than serializing as an absence, and `add_layout(kind: :score)` answers a `Score`, so every layout reads back as the class it was written as.

  ```ruby
  score = project.add_score(ensemble_type: :orchestral, concert_pitch: false)
  book  = project.add_layout(kind: :part, players: [flutist], title_override: "Flute")
  ```

  Each format renders a document of the shape that format has for a book: `#to_abc` writes a tune book, one numbered `X:` per flow separated by a blank line, which `ABC.parse_book` reads back; `#to_lilypond` writes one document with one `\header` and one `\score` per flow, each headed with its movement's own `piece`, via the new `LilyPond::BookWriter`; and because MusicXML holds one flow per document, `#to_musicxml_documents` answers one string per flow and `#to_musicxml` raises for more than one, naming the plural method. Rendering goes through a realized flow rather than through writer options, so the writers, both render plans, and both preflights know nothing about selection — and an all-flows, all-players, concert-pitch layout of one flow renders byte-identically to that flow's own output, in all three formats.

- **`HeadMusic::Content::Score`,** the layout that shows the players together. `#ordered_players` is a permutation of the layout's players in the ensemble's conventional order, and `#player_groups` splits them into the sections a score brackets. Neither is the score's own knowledge: `Instruments::ScoreOrder` already carried it per ensemble type and now exposes `#position_of(instrument)`, `#section_key_of(instrument)`, and `#group(instruments)`, sharing one section index with `#order` so ordering and grouping cannot disagree. Ties keep authored order, so two clarinets stay first and second, and a chair with an unknown instrument or none at all sorts last under a `nil` section key rather than disappearing. `ensemble_type` must be a `ScoreOrder` key or nil, which is authored order.

- **Transposition to written pitch.** A transposed layout renders each part at the pitch its player reads. The move is spelled rather than counted — the semitones decompose into a diatonic interval plus whole octaves — so a clarinet's sounding D is a written E and never an F♭, and a key signature moves by moving its tonic spelling and keeping its scale type rather than by arithmetic on fifths.

  **Each part gets its own written key**, so a mixed ensemble renders as one document: a transposed score of flute, B♭ clarinet, and horn in F carries three key signatures, and a part that picks up an A clarinet at bar 9 gains a key change there that no other part sees. The written key is derived at render time by `Notation::RenderPlan`, whose `#first_measure_key` and `#measure_key_changes` now take the part; it is a rendering fact, not content, so it reaches no model field and no schema key. MusicXML gains `<transpose>` after `<clef>`, LilyPond a `\transposition` per staff, and ABC writes the written key into `K:`. Concert pitch means sounding pitch for every part, octave transposers included. A written key needing more than seven sharps or flats raises `RenderError` naming the enharmonic to write the part in instead, rather than failing midway through assembly.

- **Writer options, each defaulting to prior behavior**: `transposed:` on `ABC.render`, `LilyPond.render`, and `MusicXML.render`; `work_title:` and `movement_number:` on `MusicXML.render`, which emit `<movement-title>` and `<movement-number>` only when a document names a whole this flow is one movement of; and `arranger:` on `LilyPond.render` and `MusicXML.render`, which emit `arranger = "..."` and `<creator type="arranger">`. A `Layout` fills the last of these from `project.credits`, which is what makes the story's arranger visible on the page; `Flow#to_*` passes none of them, so its output is unchanged. ABC has no arranger field and no book title, so a multi-tune layout's title is not rendered there.

- **Optional document keys**: `"work"` and `"source"` on a flow, `"credits"` and `"layouts"` on a project, all absent-means-none. **The schema stays 4.** The rule, now written into `references/content-schema.md`: a rename or a container restructure bumps the schema version, because an old reader would read such a document *wrongly*; a new optional key does not, because the readers look up the keys they know and never enumerate the hash. A 21.0.0 reader accepts a 21.1.0 document and ignores what it has no home for — and `"composer"` still carries the derived name, so even that loss does not reach the page. Bumping to 5 would only have made 21.0.0 reject documents it reads perfectly well.

### Changed

- **`Style::Guidelines::Contoured` judges arch and valley by the whole line.** An arch is now a melody whose trend directions are exactly ascending then descending, one rise past the reversal threshold and one fall, and a valley is the mirror. Before, an interior climax alone made an arch, so a line that rose a third, plunged a sixth, and climbed back passed arch, valley, and wave at once. Arch, valley, and wave are now mutually exclusive. Neighbor-note motion stays under the threshold, so an arch with a passing dip on the way up, or a 7-1 step at the close, still reads as an arch. **Some melodies previously graded as arch or valley now grade as wave, or as no contour at all**: in the pinned corpus, 47 of the 63 voices that passed `arch_contour_melody` and 23 of the 26 that passed `valley_contour_melody` now fail it. Nearly all of those are published cantus firmi and first-species lines that rise and fall more than once and now read as waves; a few that climb without a real reversal read as ascending only. `ascending`, `descending`, `static`, and `wave` are unchanged, as are the registered contour guides and their gates.

## [21.0.0] - 2026-09-06

The [organizing content](https://github.com/roberthead/head_music/tree/main/user-stories/epics/organizing-content.md) epic's first story. `Content::Composition` was the document, the movement, the timeline, and the credits at once, and its `Voice` was a bare melodic line with no instrument, no staff, and no performer — a shape adequate for two-voice species counterpoint and for almost nothing else. Content is now `Project` → `Flow` → `Part` → `Voice` → `Placement`, and a voice can cross between the staves of its part.

This is a breaking release. `Composition` is removed rather than deprecated, and the serialization schema goes to 4.

**Migrating from 20.1.0**, in the order a consumer will hit them:

1. **`HeadMusic::Content::Composition` is `HeadMusic::Content::Flow`.** The constant is gone, not aliased. `Flow.new` takes the same keyword arguments, and `#add_voice`, `#voices`, `#bars`, `#to_h`, `#to_abc`, `#to_lilypond`, and `#to_musicxml` all behave as they did, so most call sites need only the constant renamed. `#add_voice` now mints a `Part` per voice behind the scenes; every document this gem produced before still renders byte-identically.

2. **`LilyPond.parse` and `ABC.parse` return a `Flow`.** So do `ABC::BookParser#flows` (was `#compositions`) and `LilyPond::FlowBuilder` (was `CompositionBuilder`). These changed return type five days after the LilyPond reader shipped in 20.1.0; they are named individually here because a reader scanning for "Composition" will not otherwise notice that `parse` moved.

3. **Persisted schema-3 documents need one read-and-re-save.** `Flow.from_h` rejects a v3 hash with an error naming `Flow.from_v3_h`, which is retained read-only for this reason and removed in 22.0.0. The previous bumps shipped a key-rename recipe — v2 to v3 was "rename each placement's `pitches` key to `sounds`", doable in SQL against a jsonb column — but v3 to v4 restructures the container, so no equivalent recipe can be written. **20.1.0 is the last version that reads v3 directly.**

4. **`HeadMusic::Content::Staff` is a different class under the same name.** The 20.x `Content::Staff` was dead code, referenced by nothing but its own spec, and has been deleted; the constant is now the instance-layer staff described below. The new one takes only keyword arguments, so `Content::Staff.new(:bass_clef)` raises `ArgumentError` rather than quietly reading the clef as something else — but the readers changed too: `#default_clef` is `#clef` (and answers `nil` where none was authored, rather than falling back to treble), and `#instrument` is `#instruments_staff`, which references the catalog staff instead of an instrument.

5. **`Time::MusicalPosition#beat` is `#count`**, and `FIRST_BEAT` is `FIRST_COUNT`. `Meter` already distinguished the two — 6/8 has two beats and six counts — so a position was misnamed against the gem's own vocabulary.

6. **Grades do not move.** Every guide assesses every voice of the pinned corpus to the fitness it produced before the refactor began, which is asserted rather than assumed. Stored fitness from 20.x remains comparable.

### Added

- **`HeadMusic::Content::Project`, `Flow`, `Part`, and `Player`.** A `Project` is the document: players and flows. A `Flow` is a continuous span of music owning its own timeline — a movement, a song, a cue, an exercise. A `Player` is a chair in the project ("Flute 1", "Piano"); a `Part` is that chair's music within one flow. Pairing them that way is what makes "the flute plays in movements 1 and 3" expressible without a nullable join — there is simply no `Part` for that player in movement 2 — and what makes an instrument change *within* a part honest, since conceptually it is still the same player.

  **Containment is total; context is optional.** A voice is always in a part, always in a flow, so `voice.part.staff_system_at(bar)` never needs a nil check. What is optional is the upward reference: `Flow#project` and `Part#player` may be absent. A flow with no project is how a chunk of music lives outside a document — a cantus firmus, a scale, a parsed snippet — and it renders to ABC, LilyPond, and MusicXML with no project at all. `Project#add_flow` adopts such a flow, minting a player for each part that has none.

- **Voices orthogonal to staves.** A voice belongs to a part and *has* a staff at any given moment, so a piano voice can start in the bass staff and cross into the treble without leaving its part:

  ```ruby
  left_hand.cross_to(treble_staff, from: 5)
  left_hand.cross_to(bass_staff, from: 9)
  left_hand.staff_at(6)   # => the treble staff
  left_hand.staff_at(9)   # => back to the bass staff
  ```

  A crossing is one event, not a span: a left hand that rises for four bars and comes back down is two crossings, each authored where it happens, and a single cross-staff note is a crossing and, a bar later, another. There is no note-level special case, and nothing to overlap.

  MusicXML renders the part as one `<score-part>` with `<staves>`, a numbered `<clef>` per staff, `<voice>` per voice separated by `<backup>`, and `<staff>` per note. LilyPond renders a `\new PianoStaff` (or `\new StaffGroup` for a bracket) with one named `\new Staff` per staff and `\change Staff` at the span boundaries. Both elements are omitted for a one-voice, one-staff part, so existing output is unchanged.

- **`HeadMusic::Content::Staff` and `StaffSystem`** — the instance layer. A content staff has a line count, a clef map, and an optional reference to an `Instruments::Staff` for percussion mapping; the catalog class already owns the position-to-instrument mappings, so the instance layer references rather than re-implements it. A `StaffSystem` is an ordered set of staves with a brace, a bracket, or neither; `StaffSystem.grand_staff` and `.single_staff` are the two shapes almost everything uses.

- **`HeadMusic::Time::EventMap`** — an ordered list of `(position, value)` events answering what is in force at a position. Everything that changes partway through a flow is this shape, and it is now written once: meter, tempo, and key signature on `Flow::Timeline`; instrument and staff system on `Part`; clef on `Staff`; staff assignment on `Voice`. Lookup is a binary search over tuples computed at insert. `#change_at` answers whether a change *starts* at a position, as distinct from what is in force there, which is what a writer needs in order to decide whether to print a signature.

- **`HeadMusic::Time::KeySignatureEvent`**, carrying a signature as fifths and, optionally, the interpretation of it. Neither derives the other. A signature underdetermines its interpretation — two sharps is D major, B minor, E dorian, or A mixolydian — and an interpretation does not fix its signature either, because the two legitimately diverge: C dorian written in cantus mollis takes the parallel minor's three flats and naturalizes the sixth.

  Fifths rather than a `KeySignature` because a `KeySignature` cannot be built from a bare signature: `KeySignature.get("3 flats")` raises, so naming three flats means naming an interpretation of it, after which the stored tonic and quality are wrong whenever the interpretation disagrees. Fifths is also exactly what MusicXML stores.

- **`HeadMusic::Rudiment::Key.for_fifths(n)`** — the conventional reading of a signature that carries no interpretation of its own, for the two consumers that cannot proceed without a tonic: LilyPond's `\key`, and the `Diatonic` guideline. Signatures themselves are unbounded, since a theoretical key such as G♯ major counts each double accidental twice and reaches eight; the table stops at ±7, because past that there is no conventional major key to name. So past ±7 a `tonal_context` is required, and `change_key_signature` raises at authoring time rather than leaving every reader that needs a tonic to raise later.

- **`HeadMusic::Content::CantusFirmus::Example#to_flow(rhythmic_value:, meter:)`.** An example was a catalog datum — a pitch list with a mode and a citation — that nothing in the gem turned into music. It now realizes as a standalone flow with one part, no player, and one note per bar. Rhythm and meter are the realization's choice rather than the datum's, so they are parameters.

- **`Project#to_h` / `.from_h` / `#to_json` / `.from_json`**, and `Flow.from_v3_h`. Schema 4 round-trips players, flows, parts, voices, staff assignments, instrument changes, staff systems and their changes, clef changes, tempo and tempo changes, subtick-precise positions, and repeat structure, and round-trips a standalone flow as its own document. A tempo serializes as `{"beat_value", "beats_per_minute"}` rather than as a `"quarter = 72"` string, because `Tempo.get` reads the number by stripping non-digits and would turn 72.5 into 725.
- **`Flow.new(tempo:)`, `Flow#tempo`, and `Flow#change_tempo`**, alongside the meter and key signature equivalents. A tempo change allocates its bar the way a meter change does, and accepts a `Tempo`, a tempo name, or a `"quarter = 96"` string.
- **`Flow#remove_meter_change`, `#remove_key_signature_change`, and `#remove_tempo_change`** un-author a change, answering the removed value. 20.x cleared a change by passing `nil` to `change_*`; that now raises an `ArgumentError` naming the remover, rather than reaching a rudiment getter that would raise something unrelated.

- `Flow#position`, `Content::Position#subtick`, `Voice#assign_staff`, `Part#instrument_at` / `#staff_system_at` / `#instruments`, `Player#instruments` / `#primary_instrument` (derived from the parts, so they cannot drift from the instrument changes authored on them).

### Changed

- **Schema version 4.** `Flow#to_h` carries a `timeline` (opening meter and key signature, plus the changes to each) and `parts` (each with its instrument, instrument changes, staff system, and voices). Key and meter changes are no longer serialized per bar; a bar's own state is its repeat structure.

- **`Content::Bar` keeps only what is bar-shaped** — barlines, repeat structure, volta brackets. Its `#key_signature` and `#meter` are now derived reads of the change *authored in that bar*, and the writers `#key_signature=` and `#meter=` are gone; use `Flow#change_key_signature` and `#change_meter`. The bar had been carrying these in parallel with `Time::MeterMap` doing the same job properly and unused by `Content`.

- **`Clef.get(:tenor_clef)` is the C clef on the fourth line**, as in every theory text. It had been an alias of `vocal_tenor_clef`, the octave-down G clef of vocal scores, which won the lookup by appearing first in the catalog; that clef keeps its own name and its `tenor_g_clef` alias. `tenor_c_clef` still names the C clef too.
- **Meter and key signature changes take a bar number, and reject anything else.** Both are bar-aligned by definition, so `flow.change_meter("2:3", "3/4")` raises rather than rounding into a bar.

- **`Content::Position` wraps a `Time::MusicalPosition`.** It gains a subtick, and is normalized once at construction and then frozen — it is a sort key that `Voice#place` binary-searches over, and a mutable sort key is a wrong-note bug that raises nothing. `#eql?` and `#hash` are defined on the component tuple alongside `#<=>`; the flow deliberately takes no part in comparison, preserving the behavior `Voice#placement_at` has always guarded with. `#values` is removed in favor of `#to_a`, which now has four components. `#code` emits a subtick only when there is one, so the everyday `"bar:count:tick"` form is unchanged.

- **`Notation::RenderPlan#key_value` receives a key signature event** rather than a key signature, because the two formats want different things from it. `MusicXML::KeyMapper.mode` now takes a tonal context and returns `nil` where there is none, and the writer omits `<mode>` rather than inventing a major. LilyPond renders what is printed at the clef: the interpretation where it agrees with the signature, so a D dorian flow still prints `\key d \dorian`, and the signature where they diverge, so cantus mollis prints `\key c \minor`.

- **`Notation::ClefSelector` is demoted to a fallback.** When a staff has an authored clef the writers use it; the selector infers one from a voice's pitch range only for a part whose staves were never authored — an ABC import, a bare counterpoint exercise. The fallback stays in the writers rather than moving onto `Staff`, because it reads a *voice's* range and a staff has no back-reference to one.

- `Time::PPQN` is an alias of `Rudiment::Rhythm::PPQN` rather than a second literal 960.

### Removed

- `HeadMusic::Content::Composition`, and the dead `HeadMusic::Content::Staff` (see migration note 4).
- `HeadMusic::Time::EventMapSupport`, superseded by `Time::EventMap`.
- `Time::MusicalPosition#to_total_subticks` and its `#to_i` alias, `TempoMap#normalize_position`, and `TempoMap#meter=` — all of which existed to support the comparator fixed below.

### Fixed

- **`Time::MusicalPosition#normalize!` destroyed the last count of every bar.** `RadixCarry#carry` used `divmod`, which is correct for the 0-indexed tick and subtick and wrong for the 1-indexed count: in 3/4, `1:3:0:0` normalized to the invalid `2:0:0:0`, and so did `1:4:0:0` in 4/4 and `1:6:0:0` in 6/8. A 1-indexed component is now shifted into 0-indexed space and back.

- **`Time::MusicalPosition#<=>` was not a total order across a meter change.** It converted both positions to elapsed subticks through a single stored meter, assuming every prior bar had it, so a position in bar 4 of 4/4 compared *greater* than one in bar 5 of 7/8. Positions now compare their component tuple lexically, which needs no meter at all.

  Both bugs were latent in 20.x only because `Time` was unused by `Content`. They are on the path every note travels now.

- **A `Content::Position` rolled across a meter change kept the origin bar's count unit.** The tick carry ran under the meter of the bar the position started in, so a quarter after `1:4:480` in 4/4 landed in a 6/8 bar spelled `2:1:480`, where the same instant is `2:2:000`; the two compared unequal, so a placement rolled into the bar and one authored there did not merge. A position is now carried again under the destination bar's meter until it lands in a bar it was carried under.

- **MusicXML `<backup>` rewound a whole measure regardless of what the preceding voice wrote.** In a multi-voice part whose earlier voice ended mid-bar, the cursor went negative -- invalid MusicXML, with no error. It now rewinds by the duration actually written. Whole-measure filler rests also carry `<voice>` and `<staff>`, where before a reader stacked them onto voice 1 of staff 1 and left a grand staff's bass staff empty.

- **Every clef the gem knows renders to LilyPond** by its LilyPond name -- alto, tenor, soprano, mezzosoprano, baritone, varbaritone, french, subbass, percussion, and the quoted octave clefs `"treble_8"` and `"treble^8"` -- where an authored clef other than bass had rendered as treble.

- **A part with no voices renders**, in both writers, as a staff of whole-measure rests under its clef, key, and time, so a tacet chair keeps its line in the score. LilyPond had dropped the part; MusicXML had raised `NoMethodError`.

- **A one-staff part holding several voices renders in LilyPond as one staff** with a `\new Voice` per voice in parallel, named for its part, as MusicXML already rendered it. It had rendered as one staff per voice.

## [20.1.0] - 2026-09-05

The other half of the LilyPond export released in 20.0.0. A document written by the writer, or by hand, now reads back into a composition, so `parse(render(composition))` reproduces the music. Nothing in 20.0.0 changed shape; a consumer upgrades by upgrading.

### Added

- **LilyPond import.** `HeadMusic::Notation::LilyPond.parse(string)` reads a LilyPond document, or a bare music expression, into a `Content::Composition`: absolute and `\relative` pitches with `is`/`es` accidentals and Dutch contractions, durations with dots and carry-over, rests and whole-bar rests, chords, intra-bar ties, `\key`, `\time` (including mid-piece changes), `\clef`, bar checks, `\header` title and composer, and `\new Staff` / `\new Voice` contexts with `instrumentName` as the voice role. Everything the LilyPond writer emits reads back, so `parse(render(composition))` reproduces the music. `\version`, `\layout`, and `\midi` blocks are skipped whole, as are the header fields the reader does not use, so the Scheme in an everyday engraving preamble costs nothing. A bar-check mismatch raises `LilyPond::ParseError`; constructs outside the subset raise `LilyPond::UnsupportedFeatureError` rather than being skipped.
- `HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction)`, the inverse of `dotted_unit_fraction`, shared by the ABC and LilyPond readers.

### Changed

- **Placing a note no longer costs time linear in the voice's length.** `Content::Voice#place` scanned its placements from the front twice — once for a placement already at the position, once for the insertion point — so filling a long voice was quadratic in its length. Both are now binary searches over the position order the list already keeps. Reading a 28KB LilyPond score went from 76 seconds to under 9; the remaining time is in `Content::Position` arithmetic rather than here.

## [20.0.0] - 2026-08-30

The [style assessment model](https://github.com/roberthead/head_music/tree/main/user-stories/epics/style-assessment-model.md) epic, released together. Five stories reshaped how a guide is declared, how it grades, what it says, and what a consumer asks for — so the breaking changes below are one migration rather than five. Two notation stories ride along: LilyPond export, and note values named in each reader's own language.

**Migrating from 19.0.0**, in the order a consumer will hit them:

1. `Style::Analysis` is `Style::GuideAssessment`; `Guide#analyze(voice)` is `#assess(voice)`; `Analysis#annotations` is `GuideAssessment#guide_item_assessments`. `Style::Annotation` is `Style::Guideline`, and `Annotation::Configured` is `Style::GuideItem`.
2. Ask for a species rather than pairing its halves: `Guide.get("first_species")` returns a composite that grades melody and harmony together and combines them geometrically. The seven composite keys are new; the two `combined_first_second_third_species_*` keys are now `first_three_species_*`.
3. Grades move. Re-tiering weighs what a guide teaches above the craft it inherits, so any stored fitness from 19.0.0 is not comparable to one from 20.0.0. Regrade rather than migrate.
4. Guideline strings are i18n templates. A consumer reading `MESSAGE` constants reads `GuideItemAssessment#message` instead.

### Added

- **Composite guides.** A species is a melody guide and a harmony guide, and a student submits one line to be judged by both. `Style::Guide.get("first_species")` now answers with a `Guides::CompositeGuide` over the two, and six siblings do the same: `second_species`, `third_species`, `third_species_triple_meter`, `fourth_species`, `fifth_species`, and `first_three_species`. `Guide.all` grows 23 → 30. Which two guides make up a species, and how their grades combine, is counterpoint pedagogy; it belongs here rather than in each consuming application.

  A composite **composes grades, not items**. Merging its members' item lists cannot even be built — both members gate on `MinimumNotes.with(3)`, `GuideItem` equality is by value, and `Base.reject_duplicates` refuses the union — and would undo the tier budgets besides, putting nineteen primaries into one φ⁻¹ budget. The two levels grade by different arithmetic on purpose: rules inside a rubric trade off by weight, while a melody grade and a harmony grade must both hold.

- `Style::CompositeAssessment`, which a composite returns from `assess(voice)`. Its `fitness` is the **geometric mean** of its members' grades, so a perfect melody against a half-graded harmony reads 0.707 rather than 0.75, and either half at zero takes the whole grade to zero. `assessments` holds one `GuideAssessment` per member, and `fitness_by_category` splits the grade into the melody and harmony halves a consumer wants to show separately.

  When any member is unassessable the composite is too, and it grades on its members' **gate factors alone** — `GuideAssessment`'s own rule with the nouns raised: one member failing a precondition means the composite has not earned a grade on the other members either.

- `GuideAssessment#assessments`, answering `[self]`, so a consumer walks a leaf assessment and a composite one the same way without asking which it holds. `GuideAssessment#fitness_by_category` answers the same shape, as one group of one.

- `GuideAssessment#gate_factor` is public, and returns a `Float` for a gate-less guide rather than the Integer `1` it used to compute internally. A composite reads it when a member is unassessable.

- `composite?` and `categories` on every guide. A composite spans its members' categories rather than claiming one, so its `category` is `nil` and a consumer grouping the registry by category gains a `nil` bucket; `categories` is what answers for it. A leaf answers `[category]`.

- The rubric gains a second axis, orthogonal to tier: **strength**. Within a tier, a `:strong` guideline weighs twice a `:weak` one, normalized by that tier's own total. `Guideline.strength` declares it — `strength :weak, because: "…"`, where the reason is required for `:weak` and refused for `:strong` — and it defaults to `:strong`, so the axis is inert until a guideline opts in. An all-strong rubric grades bit-identically to one with no strength axis at all.

  Unlike tier, strength is a property of the guideline rather than of the list it was declared in: a preference is a preference in every guide that names it. It is never inherited by a subclass, because `WeakBeatDissonanceTreatment` bases two treatments that are the taught rule of their own guides. An item may override it — `Guideline.with(strength: :weak)` — for the tradition-dependent case, where `ApproachPerfectionContrarily` is prohibited in Fux and merely cautioned later.

  Eight guidelines are classified `:weak`: `FrequentDirectionChanges`, `LargeLeaps`, `LimitOctaveLeaps`, `ModerateDirectionChanges`, `MostlyConjunct`, `PreferContraryMotion`, `PreferImperfect`, and `PrepareOctaveLeaps`.

- `GuideItem#strength` and `GuideItemAssessment#strength`. The assessment's is keyword-defaulted from the item rather than required, so existing direct-construction sites keep working, and validated there as well, since it is a seam a caller can reach without going through `GuideItem`; it is stamped rather than delegated so that re-classifying a guideline later cannot silently rewrite a persisted grade.

- `HeadMusic::Style::Guidelines::SetAgainstAnotherVoice` — the definitional precondition of a harmony guide: counterpoint is a relationship between voices, and a voice alone has no harmony to assess.

- `HeadMusic::Style::Template` — renders every customer-facing string in the style module, and refuses the four ways I18n fails quietly: a template rendered with no values keeps its `%{}` without raising, a value named for a reserved key hijacks the lookup, a missing key resolves to "Translation missing: …", and a word passed as `count` silently selects a plural. Every render passes `raise: true` and is checked for a surviving interpolation.

  `Template.verify!` runs at load over the whole registry — twenty-three guide instructions, and every template the sixty-seven guide items can render, including the violation branches a guideline chooses between — so a missing entry stops `require` rather than reaching a student. It runs in English deliberately: a host application's locale must not decide whether the gem loads.

  Where a locale has no plural data, `Template.pluralize` falls back to Ruby rather than raising, and records the key it fell back for.

- British spellings for the five style strings that have them — `neighbour`, `metre`, and a bar rather than a measure. `en_GB` sits mid-chain, so German, French, Italian and Russian pick these up on the way to `en`. Note that any pluralized `en_GB` entry must carry the complete set of forms: I18n stops at a plural hash that is present but incomplete rather than continuing past it, so a partial one would raise for those four languages and never for a British reader.

- **Note values in each language.** German, Spanish, French, Italian and Russian name note values as their own teachers do — *Viertel*, *negra*, *noire*, *semiminima*, *четвертная* — rather than inheriting British words on the way to `en`. No single English serves all four inheritors: the vocabulary splits into fractional, mensural-Latin, and shape families, and French *croche* is the **eighth** where its cognate *crotchet* is the quarter, so borrowed English actively misleads. The words, their derivation rules, plural behaviour, and the sources that disagree live in `references/note-values-by-language.md`.

  The vocabulary itself lives under `head_music.rudiments`, beside the `rhythmic_unit` label already there, in three groups of eleven units each — `maxima` down to `hundred_twenty_eighth`: `rhythmic_units` (the bare unit, pluralizable, counted by `note_count_per_bar`), `note_values`, and `rest_values`. The three do not share a shape everywhere — a British note value drops the noun (*a crotchet*, not *a crotchet note*) while a British rest keeps it, and a French or Spanish rest names the concept (*soupir*, *silencio de negra*) rather than compounding the note value. Every locale also translates the words "note" and "rest" themselves. `Style::Template` gains a `scope:` keyword so style sentences borrow the rudiment vocabulary through the same seam that guards plural fallback and unfilled interpolations.

- **LilyPond export.** `HeadMusic::Content::Composition#to_lilypond` renders a composition as a complete LilyPond document string, delegating to `HeadMusic::Notation::LilyPond.render(composition, **options)` — the outward complement of the inward `Notation::<Format>.parse` interpreters, in the same facade-plus-helpers shape as the ABC and MusicXML writers. The document carries a `\version` line, a `\header` with the composition's title and composer, and a `\score` with one staff per voice in absolute pitch mode — key signature, meter, and a clef chosen per voice, with mid-piece `\key` and `\time` changes emitted at the bar where they occur, one line per bar with a trailing bar check.

  Whole-composition problems raise `Notation::LilyPond::RenderError` before any assembly — a voiceless composition, positional gaps, notes crossing barlines, a voice that ends mid-bar, unpitched sounds, and unmappable keys, durations, or alterations — so a returned string is always a complete document. Generated fixtures compile under the LilyPond CLI in the specs.

- `Rudiment::RhythmicValue#tied_chain` — the value and every link tied after it, in order, so a writer walks a chain of tied values the same way it walks a chain of one.

### Changed

- **Breaking.** `GuideAssessment.new` raises `ArgumentError` when handed a composite guide, naming `guide.assess(voice)` as the seam that grades it correctly. Flattening a composite's items into one rubric would return a plausible number computed by the wrong arithmetic.

- **Breaking.** Four renames, freeing the word "combined", which named mixed rhythm on two guides and would have named a guide composed of members as well:

  | Was | Is |
  | --- | --- |
  | `Guides::CombinedFirstSecondThirdSpeciesMelody` | `Guides::FirstThreeSpeciesMelody` |
  | `Guides::CombinedFirstSecondThirdSpeciesHarmony` | `Guides::FirstThreeSpeciesHarmony` |
  | `Guidelines::AllowedRhythmicValuesForCombined123` | `Guidelines::AllowWholeHalfQuarterNotes` |
  | `Guidelines::AllowedRhythmicValuesForFifthSpecies` | `Guidelines::AllowFifthSpeciesRhythmicValues` |

  The registry keys `combined_first_second_third_species_melody` and `..._harmony` become `first_three_species_melody` and `first_three_species_harmony`, and the locale keys move with them. The two guideline names take different shapes deliberately: the first three species allow a set small enough to say in a name, and fifth species allows that set plus eighths and ties under conditions the guideline itself decides.

- No existing guide's grade changes. Measured across the whole corpus — 3266 rows, 142 voices × 23 guides — every row is identical before and after.

- **Breaking.** `GuideItem#initialize` takes `strength:` as a keyword, so its configuration hash must now be passed explicitly — `GuideItem.new(SomeGuideline, {minimum: 3})` rather than `GuideItem.new(SomeGuideline, minimum: 3)`. `Guideline.with(minimum: 3)` is unaffected and remains the ordinary way to build one.

- **Breaking.** A guide that declares no `primary_items` raises `ArgumentError`, naming the guide and what it did declare. A guide that is all background has no subject, and grading it 1.0 in silence is the same "nothing to find fault in" confusion the gates fixed. Gate-only guides fall to the same check, deliberately. Every registered guide already declared a primary, so this closes a door rather than fixing a break.

- **Breaking.** The seven species harmony guides demote `SpeciesHarmony::HARMONIC_CORE`, `DIMINUTION_HARMONIC_CORE`, and `NoParallelPerfectWithSyncopation` to `secondary_items`, mirroring the melodic demotion. A harmony guide now weighs the dissonance treatment it teaches above the two-part craft every harmony guide shares. `SecondSpeciesHarmony` gave 9/10 of its grade to rules it did not write and now gives φ⁻¹ to `WeakBeatDissonanceTreatment` alone; a fixture failing that rule moves 0.824 → 0.698, and a parallel octave costs about half what it did.

  Each guide declares its tiers outright — `primary_items` for what it teaches, `secondary_items` splatting the shared craft constants — so the tier of every item is readable at the call site, and the specs hold the guides to the policy that a shared-core member stays background. `FirstThreeSpeciesHarmony` gains the diminution core it was missing — it covers two diminution species — and is the only guide anywhere whose set of guidelines changed.

- **`NoParallelPerfectOnDownbeats` is a taught rule in first species harmony**, not inherited background — the one exception to the demotion above. It sits in the primary tier of `Guides::FirstSpeciesHarmony` alone, weighing 0.2060 beside `NoUnisonsInMiddle` and `OneToOne` at 0.2060 each, rather than the 0.0637 the shared harmonic core would give it; no other guide is affected.

  A species guide is normally about the dissonance treatment its rhythm makes possible, and two-part craft is background. First species has no dissonance treatment, and its other two primaries are rhythm-and-texture bookkeeping — so note-against-note consonance handling is what the species teaches. Promoting the same rule in the six guides that *do* teach a dissonance treatment would weigh it as heavily as their subject, and would *raise* the grade of a submission already failing that subject by halving the weight it forgoes.

  The exception is registered in `Guides::SpeciesHarmony::HARMONIC_CRAFT_PROMOTIONS`, and the specs hold every other harmony guide to the policy. A cantus firmus doubled an octave above itself grades 0.6674 where the shared-core weighting would read 0.8300, while Fux chapter one figure 5 as published still grades exactly 1.0.

- `MostlyConjunct` marks each skip and leap at the ordinary penalty rather than `SMALL_PENALTY_FACTOR`, and says it is soft with `strength :weak` instead. The two say different things: a mark's fitness compounds into the item's own grade, so it set both how bad one instance was and how fast the item collapsed on repeats. Six leaps now grade 0.056 rather than 0.236. `SMALL_PENALTY_FACTOR` is unchanged and still used by `SecondSpeciesBreak`, which holds two severities inside one guideline.

- **Breaking.** A guide declares its guidelines in three tiers rather than one flat `RULESET`, and the tier decides how much each one counts. `gate_items` are preconditions whose fitness multiplies the grade; `primary_items` are what the guide teaches and share φ⁻¹ of the rubric; `secondary_items` are background it inherits and share φ⁻². `Guides::Base.ruleset` and every `::RULESET` constant are removed — read `guide_items`, or one tier at a time.

  Tier is the list an entry is declared in rather than a property of the entry, because the shared cores are shared objects: `SpeciesMelody::MELODIC_CORE` is splatted into six guides, and `ContourMelody` treats as background exactly what `DiatonicMelody` teaches. Guides whose tiers depend on configuration override `items_by_tier` with a keyword signature, as `ContourMelody` does.

- **Breaking.** `Style::Annotation::Configured` becomes `Style::GuideItem`: a guideline paired with the configuration one guide gives it, with `guideline` and `config` readers and value equality. It no longer answers `#new(voice)`, `#with`, or `#default_gate?`.

- **Breaking.** `Style::Analysis` becomes `Style::GuideAssessment`, and `#annotations` becomes `#guide_item_assessments`, which returns frozen `Style::GuideItemAssessment` values rather than live guideline instances. Each carries `tier`, `fitness`, `marks`, `message`, and the `guide_item` it came from.

- **Breaking.** `guide.analyze(voice)` is replaced by `guide.assess(voice)`, which returns a `GuideAssessment`, and `guide.assess_items(voice)`, which returns the assessments it grades. `Style::Guide.get` and `GuideAssessment.new` both duck-check `assess_items`: guidelines and guide items answer `assess` too, with different arguments.

- **Breaking.** Per-entry `weight` and `gate` are removed, along with `Guideline#weight`, `#gate?`, `.default_weight`, `.default_gate?`, `Contoured::DEFAULT_WEIGHT`, `MinimumThreshold.default_gate?`, and `ContourMelody::PEER_WEIGHT_BUDGET`. Tier replaces both. Whether a rule gates is the guide's editorial choice, not a property of the guideline — the same threshold can be a low gate in one guide and a stylistic minimum in another.

- **Breaking.** `Guideline.new` is private. A guideline instance is the analysis context, not a result; `Guideline.assess` is the seam, and what comes back is a `GuideItemAssessment`.

- **Breaking.** Every guide now declares a precondition, and failing one stops the assessment rather than scaling it. A voice that cannot be assessed reports `GuideAssessment#assessable? == false`, grades the product of its gates, and yields only gate assessments — the rubric is not computed. Previously a failed precondition multiplied a fully-computed rubric, so a four-note cantus firmus had its climax and leaps halved for being short.

  `assess_items` therefore returns a variable-length list. A consumer upserting rows keyed by guide item must not read a missing row as a rule that was deleted.

- **Breaking.** Grades change outside the degenerate range, deliberately. Three sources, with every affected row recorded in the story's grade table:

  | Change | Effect |
  | --- | --- |
  | The seven species harmony guides gain `SetAgainstAnotherVoice` and a three-note minimum | They raised `NoMethodError` for a voice with no companion, at every length. They grade it now. |
  | The seven species melody guides gain a three-note minimum | Each graded an empty voice 1.000 — no fault found, because there was nothing to find fault in. |
  | `FuxCantusFirmus`, `SalzerSchachterCantusFirmus` and `DiatonicMelody` split their note minimum | A three-note gate asks whether this is a melody; the eight- or five-note prescription stays a rubric item, matching `MaximumNotes`, which always was one. A four-note cantus firmus moves from 0.500 unassessable to 0.969 assessable. |
  | The species guides demote the shared melodic cores to `secondary_items` | A guide weighs its own rhythmic rules above the craft it inherits. A valid first-species line scored 0.883 against `ThirdSpeciesMelody` and now scores 0.561. |

  Grading was byte-identical to 19.0.0 through the guide-item refactor above; these are the deliberate corrections that followed it. The string changes below do not affect it.

- **Breaking.** Guideline strings move out of the classes and into the locale files. Every `MESSAGE` constant is removed. A guideline is addressed by the snake_case of its class name, so a new one needs no declaration — only entries under `head_music.style.guidelines.<key>`:

  | Key | Reads |
  | --- | --- |
  | `name` | a short label, e.g. "Minimum of eight notes" |
  | `instruction` | what to do |
  | `violations.default` | what to do differently |

  All three are templates. `GuideItem` renders them for its own configuration — `#name`, `#instruction`, `#violation_preview` — so the same guideline reads "at least three notes" in a gate and "at least eight" in a rubric. A guideline configured per guide supplies its interpolations from `self.template_values(config)`; a guide that wants a variant of the sentence names it with `violation_key:`, as `FuxCantusFirmus` does for `LargeLeaps`. A guideline that chooses between variants during the analysis itself declares them all with `.violation_keys`, as `ConsonantClimax` does for a climax dissonant with the tonic.

  All fifty-five guidelines carry a `name` and an `instruction`. The name labels the rule — "No voice crossing", "Leap recovery" — and the instruction says what to write, where the violation says what to do differently: "Keep your line on its own side of the other voice" against "Avoid crossing voices". Both are a first draft, as the guide instructions are.

  A rendered name is upcased on its first letter. A name may lead with an interpolation — `"%{contour} contour"` — whose value stays lowercase for the violation sentence that embeds it mid-clause, so "Arch contour" and "Write a melody with the arch contour" come from one locale value.

  Both stay optional. A guideline with no `name` reads its class key as a sentence, and one with no `instruction` falls back to the violation, which is already phrased imperatively — so a guideline added before anyone writes it either one still reads. Until now that fallback was every guideline's only name: forty-six of the fifty-six in the registry rendered "Avoid crossing voices" or "Triple meter dissonance treatment" out of the class key, identically in every language, and the American spelling in that second one could not be regionalized because it never passed through a locale file at all.

  The `message:` option that `SingableIntervals` and `LargeLeaps` accepted is removed with them: it passed an English sentence through the config hash, which is the thing this change exists to stop. A guide item declared with `message:` raises `ArgumentError` naming `violation_key:` rather than ignoring the key, since an unrecognized option would otherwise ride along in `config` and be dropped at render — a custom sentence vanishing with no error.

  `GuideItemAssessment#message` is now `nil` for an adherent item rather than the message it would have printed. Read `GuideItem#violation_preview` for the sentence in the abstract.

  `GuideItemAssessment#name`, and `#to_s` with it, answer the item's rendered name — "Minimum of eight notes" — rather than the guideline's class path. A consumer building a results list holds assessments rather than items, so that is where a rubric gets its labels.

- **Breaking.** Guides gain `#instruction` — what a guide asks a student to write, as distinct from how it grades what they wrote — and their names move under `head_music.style.guides.<key>.name` from the flat `<key>`. The twenty-three instructions are a first draft.

- **Breaking.** `Notation::MusicXML::ClefSelector` is now `Notation::ClefSelector`, and the old name no longer resolves. Choosing a clef for a voice's tessitura is format-independent, and the LilyPond writer reads it alongside the MusicXML one. The shared preflight checks the two writers agree on — contiguous placements, notes within barlines — move to `Notation::PreflightChecks` the same way.

## [19.0.0] - 2026-08-07

### Added

- `HeadMusic::Style::Guide` — a lookup facade over every style guide in the gem. `Guide.get("first_species_harmony")` resolves a key to a guide; an unknown key returns `nil` rather than raising, so a consumer can ask about a guide the gem does not have. `Guide.get!` raises `KeyError` instead, and `Guide.known?`, `.all`, `.keys`, and `.key_for` round out the surface. Keys are stable strings suitable for storing in a database. The registry holds twenty-three:

  | Category | Keys |
  | --- | --- |
  | `:melody` | `fux_cantus_firmus`, `salzer_schachter_cantus_firmus`, `diatonic_melody`, `first_species_melody`, `second_species_melody`, `third_species_melody`, `third_species_triple_meter_melody`, `fourth_species_melody`, `first_three_species_melody`, `fifth_species_melody`, `arch_contour_melody`, `ascending_contour_melody`, `descending_contour_melody`, `static_contour_melody`, `valley_contour_melody`, `wave_contour_melody` |
  | `:harmony` | `first_species_harmony`, `second_species_harmony`, `third_species_harmony`, `third_species_triple_meter_harmony`, `fourth_species_harmony`, `first_three_species_harmony`, `fifth_species_harmony` |

- Guides now carry identity: `.key` (snake_case of the class name), `.category` (`:melody` or `:harmony`, derived from the `SpeciesMelody`/`SpeciesHarmony` ancestry), and `.display_name` (localizable, with a computed English default). Consumers no longer need to hand-maintain a map of guide constants to categories.
- `HeadMusic::Style::Guides::Configured` — the guide-layer twin of `Annotation::Configured`. It pairs a guide class with options and answers `analyze(voice)`, so it drops into `Style::Analysis` wherever a guide class was expected. `Guides::Base.with(**options)` returns one, and `#with` layers further options without dropping earlier ones.
- `HeadMusic::Style::Guides::ContourMelody` — one configurable guide replacing the six contour subclasses: `ContourMelody.with(contour: :arch, minimum_melodic_intervals: 2)`. An invalid contour raises `ArgumentError` at configuration time, not at analysis.

### Changed

- **Breaking.** The six contour guide classes are removed: `ArchContourMelody`, `AscendingContourMelody`, `DescendingContourMelody`, `StaticContourMelody`, `ValleyContourMelody`, and `WaveContourMelody`. Their rulesets are unchanged and still reachable — by key, through the registry. Migrate constant references to `Guide.get`:

  | Removed constant | Replacement |
  | --- | --- |
  | `Guides::ArchContourMelody` | `Style::Guide.get("arch_contour_melody")` |
  | `Guides::AscendingContourMelody` | `Style::Guide.get("ascending_contour_melody")` |
  | `Guides::DescendingContourMelody` | `Style::Guide.get("descending_contour_melody")` |
  | `Guides::StaticContourMelody` | `Style::Guide.get("static_contour_melody")` |
  | `Guides::ValleyContourMelody` | `Style::Guide.get("valley_contour_melody")` |
  | `Guides::WaveContourMelody` | `Style::Guide.get("wave_contour_melody")` |

- **Breaking.** `Guides::DiatonicMelody.contour_ruleset` and `Guides::DiatonicMelody::CONTOUR_PEER_WEIGHT_BUDGET` are removed. The budget constant now lives on the guide that uses it, as `Guides::ContourMelody::PEER_WEIGHT_BUDGET`.
- **Breaking.** Neither a configured guide nor `Guides::ContourMelody` has a `::RULESET` constant — read `#ruleset` or `.ruleset(**options)` instead. `Guides::Base.ruleset` is now a method rather than a bare constant read, and `ContourMelody` deliberately does not descend from `DiatonicMelody`, so a guide whose ruleset depends on configuration raises rather than silently resolving an ancestor's ruleset through Ruby's constant lookup.
- **Breaking.** `guide.name` on a configured guide returns the underlying class name, which is shared across all six contour configurations. Persist `guide.key`, not `guide.name`; use `guide.display_name` for presentation.
- `Style::Analysis.new` now raises `ArgumentError` when given something that cannot answer `analyze`. Previously a `nil` guide — the result of an unrecognized key — surfaced much later as a `NoMethodError` on `nil`.
- **Breaking.** `Guides::Base.with` raises `ArgumentError` when given options for a guide that takes none, rather than accepting them and failing at the first `analyze` with Ruby's bare `wrong number of arguments (given 1, expected 0)`. A guide accepts configuration by declaring keywords on `.ruleset`, so `FuxCantusFirmus.with(contour: :arch)` now names the guide and the options it cannot take. `Guides::Configured` resolves its ruleset in its constructor for the same reason: a configuration error belongs at `.with`, not mid-grading.
- **Breaking.** `Instruments::Instrument.get` no longer accepts a second positional argument. The deprecated two-argument form joined its arguments with an underscore, so `Instrument.get("trumpet", "in_c")` becomes `Instrument.get("trumpet_in_c")`. It never emitted a runtime deprecation warning, so check call sites rather than logs. The two-argument form also fell back to the base instrument when the combined name did not exist — `get("trumpet", "in_q")` returned the trumpet — where `get("trumpet_in_q")` returns `nil`.
- The six contour rulesets are byte-for-byte what they were: the same ten rubric peers sharing φ⁻² evenly, `Contoured` at φ⁻¹, and the same per-contour motion gate (omitted for `static`). Fitness values are unchanged.

- **Breaking.** The ABC parser and lexer and the MusicXML writer each shed a responsibility to a collaborator, leaving no file in the gem above a RubyCritic C. Behavior is unchanged and no public method signature moved, but four constants did, and the old names no longer resolve:
  - `Notation::ABC::BodyLexer::Token` is now `Notation::ABC::Token`. The token type is consumed by `Parser` and `Preflight`, not just the lexer.
  - `Notation::ABC::BodyLexer::ChordNote` is now `Notation::ABC::ChordScanner::ChordNote`, alongside the bracket-chord scanning that produces it.
  - `Notation::ABC::Parser::REPEAT_ENDING_STYLES`, `REPEAT_STARTING_STYLES`, and `SECTION_ENDING_STYLES` are now on `Notation::ABC::RepeatTagger`, which applies the repeat and volta marks they describe.
  - `Notation::MusicXML::Writer::XML_ESCAPES` is now `Notation::MusicXML::XmlText::ESCAPES`, shared with the note and lyric writers. `Writer::INDENT` still resolves, through the same module.

## [18.0.0] - 2026-07-27

### Added

- `HeadMusic::Utilities::Accidentals` converts accidentals in a string between ASCII spellings and canonical unicode glyphs, replacing the hand-rolled `gsub` and `tr` chains that were scattered across the gem and disagreed with each other. `.to_unicode` converts whole chord symbols rather than bare pitch names — `Bbmaj7#11` becomes `B♭maj7♯11` — and `.to_ascii` converts back, emitting the spellings the gem's own parsers accept (`x` for a double sharp, never `##`). Both directions are idempotent, and conversion is all-or-nothing per accidental so a double never half-converts.
- The forward direction is safe to run over prose. Conversion happens only inside a candidate chord token, an uppercase letter name that does not continue a longer word or number, so `Above`, `Bebop`, `1.0b2`, and `0x1B2F` are untouched while `Bb`, `Ab7`, `Bbm`, and `Ebmaj7` convert. A chord-quality allowlist rescues `Bbm` and `Ebmaj7` from the word-boundary guard that protects `Above`; the allowlist was measured against a full system word list and is pinned by a spec that sweeps it.
- `##` is now accepted everywhere `bb` already was, ending the asymmetry between the two doubles. `Alteration.get("##")` resolves to `double_sharp` and `Spelling.get("C##")` returns `C𝄪`.
- The utility is deliberately narrower than `Spelling` and `Pitch` in two ways, both consequences of being safe to run over prose. It is case-sensitive, because a case-insensitive rule reads the `B` of `B7` as a flat sign — so `to_unicode("eb")` is `"eb"` while `Spelling.get("eb")` is `E♭`. And a bare token is read as an accidental rather than a pitch name — `to_unicode("bb")` is `𝄫`, the double-flat sign, while `Spelling.get("bb")` is `B♭`. Parse with `Spelling` first when a pitch name may be lowercase. `to_ascii` preserves `♮` for the same reason: dropping it would turn the valid spelling `C♮` into the different spelling `C`.

### Changed

- **Breaking.** `Spelling.get("C##")` returns a `Spelling` instead of `nil`, and the same widening applies to `Pitch`, `Note`, `KeySignature`, and ABC `K:` fields. Code that treated that `nil` as a validation signal now silently accepts double sharps.
- **Breaking.** `Alteration::PATTERN`, `Alteration::MATCHER`, and `Alteration::SYMBOLS` gain `##` and are now sorted longest-first so that a two-character spelling always matches before its one-character prefix. Code embedding these in its own regular expressions will see different matches.
- **Breaking.** `Alteration.symbols` now returns `SYMBOLS` rather than a separately derived list that disagreed with it.
- **Breaking.** `Utilities::HashKey` normalizes ASCII accidentals before mapping them to word suffixes, so ASCII and unicode spellings of the same accidental now produce the same key. Previously it handled ASCII `#` but not ASCII `b`, so `"C#"` keyed to `:c_sharp` while `"Bb"` keyed to `:bb`. Now `"Bb"` keys to `:b_flat`, `"Bbb"` to `:b_double_flat`, and `"Cx"` to `:c_double_sharp`. Words containing those letters are unaffected — `:bass_clarinet` and `:blues_major_pentatonic` are unchanged — because normalization goes through the prose-safe `Utilities::Accidentals` rather than a bare substitution. The glyph-to-word table is now derived from `Alteration` rather than hard-coded, leaving `alterations.yml` as the single inventory.
- `Utilities::HashKey` is class-methods-only, matching `Utilities::Case`. `.new` and `#to_sym` are gone; `.for` was already the only entry point in use. The per-instance memo they wrapped could never be hit twice, since each instance was discarded after one call.
- **Breaking.** `Analysis::Dyad` gains double sharps in its enharmonic universe, which were previously built as candidates and then silently discarded by the parser. Candidate spellings grow from 28 to 35, and a major third gains three respellings.
- **Breaking.** `Rudiment::Scale::SCALE_REGEX` is removed. It was unreferenced, and its singles-only `[#b]?` was an instance of the asymmetry this release closes.
- **Breaking.** `KeySignature` and `Scale` memoization keys change for identifiers containing accidentals. `Fx`, `C##`, and `F𝄪` now unify onto one cache entry, as they name the same key signature.
- `Rudiment::Note::PITCH_PATTERN` no longer truncates a double sharp. `"C##4"` previously parsed as `["C", "#", nil]`, silently losing the register, because the optional quantifier bound to the pattern's final alternative rather than to the whole alternation.
- `Alteration#representations` now spans every symbol record rather than only the primary one, so a double sharp reports `"##"` alongside `"x"` and `𝄪`. It also accepts a `locale_code:` keyword and memoizes per locale, since the list includes the localized `#name`.
- An ABC `K:` field naming a double-altered tonic still raises `ParseError`, but with a message that says so — `Cannot express double-altered tonic Cx in an ABC K: field` rather than the incidental `Unrecognized mode` it produced when the narrower key pattern failed to match the accidental.

### Removed

- `Content::Staff` no longer prints to standard output when it cannot resolve a clef key. It previously wrote `Warning: Clef '...' not found.` and `Using instrument clef.` to stdout. The fallback behavior is unchanged — an unrecognized key still resolves to the instrument's clef when an instrument is present, and to the treble clef otherwise — it is simply no longer announced.

## [17.5.0] - 2026-07-21

### Added

- Sung text (lyrics) can be attached to the notes of a voice. `HeadMusic::Content::Placement#sing(text, verse:, hyphen_after:)` assigns a syllable to a placement, keyed by verse so a note carries at most one syllable per verse and any number of verses (`glo` on verse 1, `peace` on verse 2 of the same note). A new immutable `HeadMusic::Content::Syllable` value object stores only the minimal linguistic fact — `text`, `verse`, and a `hyphen_after` boolean marking that the word continues onto the next sung note; the MusicXML `syllabic` value (`single`/`begin`/`middle`/`end`) is derived at render time rather than stored, and a melisma is represented by the absence of a syllable on the held notes rather than a stored flag. Syllables serialize through `Placement#to_h` and round-trip through the composition hash deserializer, validated at the import boundary by `Composition::SchemaValues` (non-empty text, a positive-integer verse, and no duplicate verse per placement).
- The MusicXML writer emits a `<lyric number="N">` element as the last child of each `<note>`, on the lead note of a chord only and the attack of a tied chain only, deriving `<syllabic>` from the `hyphen_after` booleans of the syllable and its predecessor in the same verse and XML-escaping the text. Held notes of a melisma carry no `<lyric>`, matching MusicXML's continuation-by-absence. ABC `w:` lyric-line input and the MusicXML `<extend/>` melisma line remain out of scope for a future release.

## [17.4.0] - 2026-07-20

### Changed

- Internal refactoring for clarity and maintainability, with no changes to public behavior or output. Complex classes were split along their natural seams by extracting focused collaborators and value objects, each with its own spec: `MusicXML::Preflight` and `MusicXML::RenderPlan` from the MusicXML `Writer`; `Instruments::InstrumentName`, `InstrumentCatalog`, and `StaffProfile` from `Instrument`; `Analysis::ChordAnalysis` from `PitchCollection`; `Content::SoundResolver` from `Placement`; `Time::SmpteConverter` and `MusicalTimeConverter` from `Conductor`; `Composition::SchemaValues` from `HashDeserializer`; `Pitch::NaturalStep` from `Pitch`; `Voice::MelodicLine` from `Voice`; `Dyad::ChordImplication` from `Dyad`; and `ABC::Preflight` plus per-voice note-assembly moved onto `ABC::VoiceState` in the ABC parser.
- Shared value-object equality was consolidated into a `ValueEquality` mixin, and duplication was reduced across the style guides, notation writers, and rudiments.
- Nested classes that had outgrown their host files were given their own files without changing their constant paths: `Named::Locale` and `Named::LocalizedName`, `Voice::MelodicNotePair`, `Spelling::EnharmonicEquivalence`, and `Style::Annotation::Configured`.

## [17.3.0] - 2026-07-19

### Added

- The MusicXML writer emits `<beam>` elements so exported notation renders with correct beaming rather than relying on renderer-side auto-beaming (which mis-groups compound meters). Default beam groups are derived from the meter at render time — the dotted-quarter pulse for compound meters (6/8, 9/8, 12/8), the beat for simple quarter meters, and the whole bar for 3/8 — via a new `HeadMusic::Rudiment::Meter#beam_group_unit`. Grouping resolves at the notated-note level, so a tied chain beams correctly across its own noteheads, and secondary beams (sixteenths and finer) render with begin/continue/end runs plus forward/backward partial-beam hooks.
- The ABC interpreter captures authored beam grouping from inter-note spacing: adjacent notes beam together and a space breaks the beam, honored verbatim (even across a beat). This is carried on a new tri-state `HeadMusic::Content::Placement#beam_break_before` flag (`nil` = meter default, `true` = break, `false` = join) that overrides the default on output, serializes through `to_h`/`from_h`, and survives an ABC parse → render → parse round trip (the writer suppresses the space within an authored group).

## [17.2.0] - 2026-07-19

### Added

- The ABC interpreter reads explicit ties (`-`) between notes. `E3-E2` fuses into one sounding note whose rhythmic value carries the authored split (`dotted quarter tied to quarter`), overriding the resolver's greedy decomposition, and tie chains (`C2-C2-C2`) nest into a single value. A tie between notes of different pitches, a dangling tie, or a tie to a rest raises `ParseError`; a tie across a barline raises `ParseError` ("Ties across barlines are not yet supported") pending a future release.

## [17.1.0] - 2026-07-18

### Changed

- The MusicXML writer renders chord placements as stacked notes rather than raising `RenderError`: a chord emits one `<note>` per pitched sound, ordered low to high, with `<chord/>` on all but the lowest note, all sharing the placement's rhythmic value. Tied chords emit a full chord stack per tie-link. The writer still raises `RenderError` for placements containing unpitched sounds (percussion rendering lands in a future release).

## [17.0.0] - 2026-07-18

### Added

- `HeadMusic::Rudiment::UnpitchedSound` — an unpitched sound (a drum hit, a clap, a percussive knock), backed by the instruments catalog. `.get(nil)` returns the generic instrument-less sound; `.get(name_or_alias_or_instrument)` resolves through the catalog (aliases canonicalize to the instrument's name key), and pitched instruments are valid hit surfaces — a knock on a violin body is unpitched.
- Placements hold sounds: `HeadMusic::Content::Placement#sounds` is the source of truth (pitched and unpitched, mixed within one placement allowed), with `#pitches` as the pitched subset. `Voice#place` accepts pitches, unpitched sounds, instruments, or mixed arrays.
- New placement predicates: `sounded?` (any sound), `pitched?` (any pitched sound), `pitched_note?`, and `unpitched_note?`.

### Changed

- **Breaking**: serialization schema is now version 3. Placement hashes carry a `"sounds"` array instead of the `"pitches"` key — pitched sounds serialize as pitch strings (unchanged), unpitched sounds as `{"unpitched" => name_key}` objects (`null` name key for the generic sound) — and `Composition.from_h` no longer accepts schema version 2 hashes. Persisted v2 data (e.g. in a jsonb column) must be migrated by renaming each placement's `"pitches"` key to `"sounds"`; the pitch strings themselves are unchanged.
- **Breaking**: `Placement#note?` now means exactly one sound of any kind, so chords are no longer `note?`; `Placement#chord?` counts pitched sounds (two or more).
- **Breaking**: `Voice#place` raises `ArgumentError` on an unparseable value instead of quietly placing a rest.
- The ABC and MusicXML writers raise `RenderError` when asked to render an unpitched sound (unpitched rendering lands in a future release).

## [16.0.0] - 2026-07-17

### Added

- Chords in the content model: `HeadMusic::Content::Placement` holds a `pitches` array (empty for a rest, two or more for a chord) and derives `#pitch` as the highest pitch, so melodic analysis follows the top line. `Placement#chord?` distinguishes chords. `Voice#place` accepts a single pitch or an array of pitches; a chord is one rhythmic event.
- `Voice#place` merges a placement at an already-occupied position into the existing placement when the rhythmic value matches (the pitch union is duplicate-free, so re-placing a pitch is idempotent), and raises `ArgumentError` when it does not. A position within a voice holds at most one placement, enforcing structurally that simultaneous pitches with distinct durations belong in separate voices.

### Changed

- **Breaking**: serialization schema is now version 2. Placement hashes carry a `"pitches"` array instead of the singular `"pitch"` key (rests serialize as `"pitches" => []`), and `Composition.from_h` no longer accepts schema version 1 hashes.
- **Breaking**: `Placement#pitch` is a derived reader (highest of `pitches`, `nil` for a rest) rather than a stored attribute, and `Placement#note?` returns a boolean rather than the pitch object.
- The ABC and MusicXML writers raise `RenderError` when asked to render a chord placement (chord rendering lands in a future release) rather than silently emitting only the top pitch.

## [15.2.0] - 2026-07-16

### Added

- `HeadMusic::Content::Composition#to_h` / `.from_h` — lossless, JSON-safe hash serialization of a composition (schema_version 1). The hash captures name, key signature, meter, composer, origin, voices with roles and ordered placements (tick-precise positions, rhythmic values including ties, exact pitch spellings, rests as `null`), sparse per-bar state (mid-piece key and meter changes, repeat and volta structure), and comments. `from_h` rebuilds through the public builder API and raises `ArgumentError` with path context on malformed input; unknown keys are ignored so the format can evolve additively.
- `HeadMusic::Content::Composition#to_json` / `.from_json` — thin delegates over `to_h`/`from_h`.
- `#to_h` on `Content::Voice`, `Content::Placement`, `Content::Bar`, and `Content::Comment`.

**Schema v1 is a compatibility surface**: hashes persisted by downstream apps (e.g. in a jsonb column) must keep loading. Additive optional keys are fine within version 1; any change to existing keys' shape or meaning requires a `schema_version` bump.

### Fixed

- `RhythmicValue.get` now parses tied value strings ("half tied to eighth", including chained ties), so tied durations round-trip through `#to_s`.
- `Bar#key_signature=` and `Bar#meter=` coerce strings via `KeySignature.get` / `Meter.get`, so `change_meter(4, "6/8")` no longer stores a raw String.
- `Voice` placement ordering is now stable: notes placed at the same position (chords) keep their insertion order.
- `Composition#change_key_signature` / `#change_meter` no longer raise for a bar earlier than the first placement (e.g. a pickup bar).

## [15.1.0] - 2026-07-07

### Added

- `HeadMusic::Content::Composition.to_musicxml` for MusicXML export
- `HeadMusic::Content::Composition.to_abc` for ABC Notation export. ABC can round-trip to and from Composition.

## [15.0.0] - 2026-07-06

### Added

- `HeadMusic::Style::Guidelines::MinimumMelodicIntervals` — a sufficiency gate on the number of moving melodic intervals, so a line that never (or barely) moves reads as a non-attempt rather than a flawed melody (`MinimumMelodicIntervals.with(2)`). The contour guides use it; `StaticContourMelody` omits it so a repeated single pitch remains a legitimate static contour.
- `weight:` and `gate:` options on `Annotation.with` — any ruleset entry can now carry a rubric weight or be marked as a gate, and `Configured#with` layers options so presets compose (e.g. `MinimumNotes.with(5).with(gate: true)`)

### Changed

- **Breaking:** `Analysis#fitness` is now a gated weighted rubric instead of an unweighted geometric mean: the product of the gate fitnesses multiplies a weighted arithmetic mean of the remaining (rubric) rules. Every fitness value shifts numerically; downstream consumers that compare grades against stored thresholds must recalibrate.
- Non-attempts now grade zero: sufficiency guidelines (`MinimumNotes`, `MinimumMelodicIntervals`) act as graded gate multipliers, so an empty or insufficient line scales the whole grade down to 0 instead of averaging against the other rules.
- Contour guides weight `Contoured` at the inverse golden ratio (φ⁻¹ ≈ 0.618) with their ten rubric peers sharing φ⁻² evenly, so a wrong-contour but otherwise perfect line grades exactly ~0.618 (`HeadMusic::GOLDEN_RATIO_INVERSE`)
- `Diatonic` and `MaximumNotes` are rate-normalized (fitness raised to 1/note-count), so grades are length-invariant: the same violation rate scores the same in an eight-note line as in a sixteen-note line
- Broken-but-real work now lands on a deliberate soft floor (roughly 0.3–0.55): rate-normalized rules bottom out near φ⁻¹ and the arithmetic mean averages them, so a gate-passing melody that breaks most of the rubric grades substantially below perfect without collapsing toward the gated zero of a non-attempt

## [14.0.0] - 2026-07-05

### Added

- `HeadMusic::Style::Guidelines::Contoured` — configurable guideline judging a melody against a chosen contour (`Contoured.with(:arch)` and five other keys: `ascending`, `descending`, `valley`, `wave`, `static`). Predicates are trend-based rather than strictly monotonic; a wrong contour receives a single mark spanning the melody. Unknown contour keys raise `ArgumentError` at guide-definition time.
- Six contour guides subclassing `Guides::DiatonicMelody`, each appending the configured `Contoured` guideline to the inherited ruleset: `ArchContourMelody`, `AscendingContourMelody`, `DescendingContourMelody`, `StaticContourMelody`, `ValleyContourMelody`, `WaveContourMelody`
- Contour judgments deliberately complement `ConsonantClimax`: an arch requires only an interior climax pitch level, leaving climax uniqueness and consonance to the existing guideline

## [13.0.0] - 2026-07-05

### Added

- `HeadMusic::Notation::NotationStyle` — named notation traditions (`british_brass_band`, `german`, `italian`, `concert_pitch`) resolved as sparse overlays on a `default` style, backed by `notation_styles.yml`, with `.get`/`.default` factories and `#notation_for`
- `HeadMusic::Notation::InstrumentNotation` — the resolved notation value object (clef, sounding transposition, staves, and recorded register/clef alternatives) with value equality
- `Instrument#notation(style:)` — notate an instrument through a chosen notation style, defaulting to `default`

### Changed

- Notation concerns (clef, sounding transposition, staff structure) now live in `NotationStyle` instead of on the instrument. `Instrument`'s notation methods (`default_staves`, `default_clefs`, `sounding_transposition`, etc.) delegate to the default style and resolve to the same values as before.
- `Instrument#staff_schemes` now returns only the instrument's default scheme; named schemes (brass-band, German/Italian bass clarinet, and register/clef alternatives) have moved into notation styles.

### Removed

- `staff_schemes` data from `instruments.yml` and the internal `staff_schemes` plumbing on `Instrument`. Per-instrument notation conventions are now expressed as notation styles. (Breaking change — hence the major version bump.)

## [12.6.0] - 2026-07-03

### Added

- `DiatonicMelody` guide: a free diatonic melody not bound to cantus firmus start/end constraints (note-count range configurable, defaulting to 5–24)
- Configurable guidelines — a guideline can now carry configuration into a `RULESET` via `Annotation.with(...)` (wrapped in `Annotation::Configured`):
  - `MinimumNotes` / `MaximumNotes` — configurable note-count floor and ceiling (`AtLeastEightNotes` / `UpToFourteenNotes` retained as named defaults)
  - `NoteCountPerBar` — configurable `count` and `rhythmic_value` (unifies `OnePerBar`, `TwoPerBar`, `ThreePerBar`, `FourPerBar`)
  - `DirectionChanges` — configurable `maximum_notes_per_direction` (unifies `ModerateDirectionChanges` and `FrequentDirectionChanges`)
  - Configurable thresholds on `SingableRange`, `MostlyConjunct`, `LimitOctaveLeaps`, and `SecondSpeciesBreak`

### Changed

- Extracted `HeadMusic::Style::Guides::Base` for shared guide analysis behavior; `SpeciesMelody` and `SpeciesHarmony` now inherit from it
- Hoisted the guidelines common to every guide into `MELODIC_CORE` / `HARMONIC_CORE` constants on the species base classes
- `SingableRange`'s message now reflects the configured range
- Renamed the `quality` rake task to `validate`

## [12.5.0] - 2026-04-08

### Changed

- Improved fifth-species counterpoint guidelines
- Code quality improvements

### Removed

- Combined 2+3+4 species guides and their guidelines

## [12.4.0] - 2026-04-06

### Added

- Fifth-species (florid) counterpoint guides
- Standard and alternate instrument tunings

### Fixed

- Ukulele family stringings, tunings, and range data

## [12.3.0] - 2026-02-25

### Added

- Fourth-species counterpoint guides

### Changed

- Code quality pass

## [12.2.0] - 2026-02-24

### Changed

- Improved guidelines for first-bar entry

## [12.1.0] - 2026-02-24

### Changed

- Refactored species guidelines into separate first-bar, middle-bar, and final-bar rules
- Unified `FinalBarWholeNote` and `FinalBarDottedHalfNote` into `NoteFillsFinalBar`

## [12.0.1] - 2026-02-23

### Changed

- Renamed triple-meter guides

## [12.0.0] - 2026-02-21

### Added

- Third-species 3:1 guidelines
- Allow a descending minor sixth as a singable interval

### Changed

- Extracted shared base classes for guides and step-to-final-note guidelines
- Refactored third-species dissonance handling and other files to reduce code smells

## [11.8.0] - 2026-02-16

### Added

- `ThirdSpeciesMelody` and `ThirdSpeciesHarmony` guides
- `ThirdSpeciesDissonanceTreatment` guideline
- `FourToOne` guideline
- Third-species counterpoint reference document

## [11.7.0] - 2026-02-13

### Added

- Parallel-perfect check for first species

### Changed

- `Analysis#fitness` now uses the geometric mean

## [11.6.1] - 2026-02-12

### Added

- Additional test coverage for the two-to-one guideline

### Fixed

- Accept an implied rest in the first bar of second-species counterpoint

## [11.6.0] - 2026-02-10

### Added
- Second-species counterpoint style guides: `SecondSpeciesMelody` and `SecondSpeciesHarmony`
- New guidelines for second-species counterpoint:
  - `TwoToOne` — enforces two half notes per cantus firmus whole note (with optional half-rest opening)
  - `WeakBeatDissonanceTreatment` — dissonant weak beats must be passing tones
  - `NoParallelPerfectOnDownbeats` — forbids parallel perfect consonances on consecutive downbeats
  - `NoParallelPerfectAcrossBarline` — forbids parallel perfect consonances from weak beat to following downbeat
  - `NoStrongBeatUnisons` — forbids unisons on interior downbeats
- Pedagogical reference document for second-species counterpoint (`references/second-species-counterpoint.md`)

## [11.0.0] - 2026-01-05

### Changed
- **BREAKING**: Widened ActiveSupport dependency from `~> 7.0` to `>= 7.0, < 10` to support Rails 8.x
- Improved I18n initialization to be non-destructive:
  - No longer overwrites `I18n.default_locale` (allows Rails apps to control their default)
  - Adds HeadMusic locales to `available_locales` instead of replacing them
  - Only sets fallbacks if not already configured by the application
- Updated CI workflow to test against both ActiveSupport 7.x and 8.x

### Fixed
- Fixed compatibility issue with Rails 8.1.x applications

## [10.0.0] - 2025-12-01

### Changed
- Internal release for testing

## [9.0.0] - 2025-10-24

### Added
- Added `HeadMusic::Rudiment::Pitch::Parser` for strict pitch parsing
- Added `HeadMusic::Rudiment::RhythmicValue::Parser` for rhythmic value parsing
- Both parsers provide standardized `.parse()` class method API

### Changed
- `Pitch.from_name` now uses `Pitch::Parser` internally
- `RhythmicValue.get` now uses `RhythmicValue::Parser` internally
- `Note.get` now parses "pitch rhythmic_value" strings inline without Parse module

### Removed
- **BREAKING**: Removed `HeadMusic::Parse::Pitch` class
- **BREAKING**: Removed `HeadMusic::Parse::RhythmicValue` class
- **BREAKING**: Removed `HeadMusic::Parse::RhythmicElement` class
- **BREAKING**: Removed entire `HeadMusic::Parse` module

### Migration Guide

If you were using the removed Parse classes, migrate as follows:

```ruby
# Before (v8.x)
parser = HeadMusic::Parse::Pitch.new("C#4")
pitch = parser.pitch

# After (v9.x)
pitch = HeadMusic::Rudiment::Pitch.get("C#4")
# or for strict parsing:
pitch = HeadMusic::Rudiment::Pitch::Parser.parse("C#4")
```

```ruby
# Before (v8.x)
parser = HeadMusic::Parse::RhythmicValue.new("dotted quarter")
value = parser.rhythmic_value

# After (v9.x)
value = HeadMusic::Rudiment::RhythmicValue.get("dotted quarter")
# or for strict parsing:
value = HeadMusic::Rudiment::RhythmicValue::Parser.parse("dotted quarter")
```

```ruby
# Before (v8.x)
parser = HeadMusic::Parse::RhythmicElement.new("F#4 dotted-quarter")
note = parser.note

# After (v9.x)
note = HeadMusic::Rudiment::Note.get("F#4 dotted-quarter")
```

## [8.2.1] - 2025-06-21

### Added
- Added missing modern instruments to all locales (ukulele family, electronic instruments, world instruments)
- Added pitched/unpitched instrument classifications to all non-English locales
- Added new instrument families: bass_drum, tambourine, and celesta

### Changed
- Improved instrument family classifications (added fretted/unfretted, valve categorizations)
- Removed incorrect percussion classification from harpsichord and clavichord

### Fixed
- Fixed Russian translation errors (tritone and perfect_unison)

## [8.2.0] - 2025-06-20

### Added
- Added comprehensive GitHub Actions CI/CD workflows (test matrix, security scanning, automated releases)
- Added security tooling with bundler-audit for vulnerability scanning
- Added YARD documentation generation with kramdown support
- Added SimpleCov coverage tracking with 90% threshold and branch coverage
- Added Dependabot configuration for automated dependency updates
- Added inclusive CONTRIBUTING.md with comprehensive contribution guidelines
- Added complete CHANGELOG.md tracking version history
- Added GitHub issue templates (bug reports, feature requests) and PR template
- Added gemspec metadata fields for better gem documentation and security
- Added rubygems_mfa_required for enhanced security

### Changed
- Standardized Ruby version requirement to 3.3.0 across all configuration files
- Updated and organized development dependencies (removed deprecated codeclimate-test-reporter)
- Enhanced .gitignore with modern patterns and restored Gemfile.lock tracking
- Improved RuboCop configuration (increased MultipleMemoizedHelpers max to 12)
- Enhanced Rakefile with quality, documentation, and coverage tasks

### Removed
- Removed outdated Travis CI and CircleCI configurations (replaced with GitHub Actions)

## [8.1.1] - 2024-12-20

### Changed
- Tweaked gemspec summary

## [8.1.0] - 2024-12-20

### Added
- Enhanced solmization support

### Changed
- Code cleanup and improvements
- Improved spec coverage
- Refactored melodic intervals to separate pitch and note concerns

## [8.0.2] - 2024-12-19

### Fixed
- RuboCop style fixes

### Changed
- Improved RuboCop configuration

## [8.0.0] - 2024-12-19

### Changed
- Major reorganization: moved specs into folders
- Organized models into modules for better structure
- **BREAKING**: Module structure changes may require updates to require statements

## [7.0.5] - 2024-01-20

### Changed
- Upgraded to Ruby 3.3.0
- Improvements to Spanish translations of recorder

## [7.0.4] - 2024-01-15

### Added
- Rudiment translations
- Instrument classification translations
- Interval translations

## [7.0.3] - 2024-01-10

### Added
- Russian instrument translations using Cyrillic characters
- Spanish translations for instruments

### Changed
- Uncapitalized languages in Italian and Spanish translations
- Spanish translation corrections and improvements
- Translation file cleanup

## [7.0.2] - 2023-12-15

### Changed
- Various improvements and bug fixes

## [7.0.1] - 2023-12-10

### Changed
- Minor improvements and bug fixes

## [7.0.0] - 2023-12-01

### Changed
- Major version bump indicating significant changes
- **BREAKING**: Check upgrade guide for migration instructions

## [6.0.1] - 2023-11-15

### Fixed
- Bug fixes and improvements

## [6.0.0] - 2023-11-01

### Changed
- Major architectural improvements
- **BREAKING**: API changes may require code updates

## [5.0.0] - 2023-10-15

### Changed
- Significant refactoring of core components
- **BREAKING**: Check documentation for new API

## [4.0.1] - 2023-09-20

### Fixed
- Minor bug fixes

## [4.0.0] - 2023-09-15

### Added
- Expanded instrument support
- Instrument data improvements

### Changed
- Enhanced Instrument class functionality

## [3.0.1] - 2023-08-20

### Fixed
- Minor improvements and fixes

## [3.0.0] - 2023-08-15

### Changed
- Major version update with architectural improvements
- **BREAKING**: Significant API changes

## [2.0.0] - 2023-07-01

### Changed
- Major refactoring of core functionality
- **BREAKING**: API redesign

## [1.0.0] - 2023-06-01

### Added
- First stable release
- Complete music theory rudiments implementation
- Comprehensive scale and interval support
- Basic composition and voice handling

## [0.29.0] - 2023-05-15

### Added
- Additional music theory features
- Improved documentation

## [0.28.0] - 2023-05-01

### Changed
- Performance improvements
- Code organization enhancements

## Earlier versions

For changes in versions prior to 0.28.0, please refer to the git history.

[Unreleased]: https://github.com/roberthead/head_music/compare/v21.0.0...HEAD
[21.0.0]: https://github.com/roberthead/head_music/compare/v20.1.0...v21.0.0
[20.1.0]: https://github.com/roberthead/head_music/compare/v20.0.0...v20.1.0
[20.0.0]: https://github.com/roberthead/head_music/compare/v19.0.0...v20.0.0
[19.0.0]: https://github.com/roberthead/head_music/compare/v18.0.0...v19.0.0
[18.0.0]: https://github.com/roberthead/head_music/compare/v17.5.0...v18.0.0
[17.5.0]: https://github.com/roberthead/head_music/compare/v17.3.0...v17.5.0
[17.3.0]: https://github.com/roberthead/head_music/compare/v17.2.0...v17.3.0
[17.2.0]: https://github.com/roberthead/head_music/compare/v17.1.0...v17.2.0
[17.1.0]: https://github.com/roberthead/head_music/compare/v17.0.0...v17.1.0
[17.0.0]: https://github.com/roberthead/head_music/compare/v15.2.0...v17.0.0
[15.2.0]: https://github.com/roberthead/head_music/compare/v15.0.0...v15.2.0
[15.0.0]: https://github.com/roberthead/head_music/compare/v14.0.0...v15.0.0
[14.0.0]: https://github.com/roberthead/head_music/compare/v13.0.0...v14.0.0
[13.0.0]: https://github.com/roberthead/head_music/compare/v12.6.0...v13.0.0
[12.6.0]: https://github.com/roberthead/head_music/compare/v12.5.0...v12.6.0
[12.5.0]: https://github.com/roberthead/head_music/compare/v12.4.0...v12.5.0
[12.4.0]: https://github.com/roberthead/head_music/compare/v12.3.0...v12.4.0
[12.3.0]: https://github.com/roberthead/head_music/compare/v12.2.0...v12.3.0
[12.2.0]: https://github.com/roberthead/head_music/compare/v12.1.0...v12.2.0
[12.1.0]: https://github.com/roberthead/head_music/compare/v12.0.1...v12.1.0
[12.0.1]: https://github.com/roberthead/head_music/compare/v12.0.0...v12.0.1
[12.0.0]: https://github.com/roberthead/head_music/compare/v11.8.0...v12.0.0
[11.8.0]: https://github.com/roberthead/head_music/compare/v11.7.0...v11.8.0
[11.7.0]: https://github.com/roberthead/head_music/compare/v11.6.1...v11.7.0
[11.6.1]: https://github.com/roberthead/head_music/compare/v11.6.0...v11.6.1
[11.6.0]: https://github.com/roberthead/head_music/compare/v11.5.1...v11.6.0
[11.0.0]: https://github.com/roberthead/head_music/compare/v9.1.0...v11.0.0
[9.0.0]: https://github.com/roberthead/head_music/compare/v8.4.0...v9.0.0
[8.2.0]: https://github.com/roberthead/head_music/compare/v8.1.1...v8.2.0
[8.1.1]: https://github.com/roberthead/head_music/compare/v8.1.0...v8.1.1
[8.1.0]: https://github.com/roberthead/head_music/compare/v8.0.2...v8.1.0
[8.0.2]: https://github.com/roberthead/head_music/compare/v8.0.0...v8.0.2
[8.0.0]: https://github.com/roberthead/head_music/compare/v7.0.5...v8.0.0
[7.0.5]: https://github.com/roberthead/head_music/compare/v7.0.4...v7.0.5
[7.0.4]: https://github.com/roberthead/head_music/compare/v7.0.3...v7.0.4
[7.0.3]: https://github.com/roberthead/head_music/compare/v7.0.2...v7.0.3
[7.0.2]: https://github.com/roberthead/head_music/compare/v7.0.1...v7.0.2
[7.0.1]: https://github.com/roberthead/head_music/compare/v7.0.0...v7.0.1
[7.0.0]: https://github.com/roberthead/head_music/compare/v6.0.1...v7.0.0
[6.0.1]: https://github.com/roberthead/head_music/compare/v6.0.0...v6.0.1
[6.0.0]: https://github.com/roberthead/head_music/compare/v5.0.0...v6.0.0
[5.0.0]: https://github.com/roberthead/head_music/compare/v4.0.1...v5.0.0
[4.0.1]: https://github.com/roberthead/head_music/compare/v4.0.0...v4.0.1
[4.0.0]: https://github.com/roberthead/head_music/compare/v3.0.1...v4.0.0
[3.0.1]: https://github.com/roberthead/head_music/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/roberthead/head_music/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/roberthead/head_music/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/roberthead/head_music/compare/v0.29.0...v1.0.0
[0.29.0]: https://github.com/roberthead/head_music/compare/v0.28.0...v0.29.0
[0.28.0]: https://github.com/roberthead/head_music/releases/tag/v0.28.0
