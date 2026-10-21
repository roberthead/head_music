# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Humdrum `**kern` import and export.** `HeadMusic::Notation::Kern.parse` reads a `**kern` document into a flow, and `Kern.render` and `Flow#to_kern` write one back. Each kern spine becomes a voice, parts and staves come from `*part` and `*staff` tags, and spine splits, joins, exchanges, and partial terminations map sub-spines onto voices of one part. The reader takes pitches, durations, rests, chords, ties across barlines, pickups and short final bars, repeat barlines, key signatures and their designations, meters, tempos, clefs, `*I` names (as players) and vocal and piano codes, `**text` lyrics, and a `Work` with a composer credit from the reference records. Every voice spans the whole flow, padded with rests, so a flow read back from what the writer wrote is the flow it was. All 366 readable chorales of the Bach 370 corpus parse, write back to themselves, and render to MusicXML and LilyPond; four hold bars the model cannot, and raise.
- A standalone flow's JSON keeps the players its parts carry, as a sparse `"part_players"` list with a `"player"` index on each such part, within schema 4. Project documents are unchanged: the project's own player indexes remain the record of which chair a part fills.
- The LilyPond parser reads a `\new PianoStaff` or `\new StaffGroup` as one part: its named staves become the part's staff system, with clefs from each staff's opening `\clef`, and its voices are assigned to their staves, crossing with `\change Staff` at a barline, including between the halves of a tied note. A staff filled only with whole-bar rests keeps its place without a voice. The LilyPond writer names each voice of a staff group for its role (`\new Voice = "right hand"`), so grand-staff parts round-trip.
- `HeadMusic::Rudiment::Soundable` names the role of anything a placement can sound. `Pitch` and `UnpitchedSound` include it, and `SoundResolver` passes any `Soundable` through unchanged.
- `HeadMusic::Rudiment::Articulation` (staccato, staccatissimo, accent, tenuto, marcato), `Ornament` (trill, mordent, inverted mordent, turn), and `Dynamic` (the levels *ppp* to *fff* and the accents *sf*, *sfz*, *rfz*, *fp*) are catalogs read from YAML, found with `.get` by key or alias in any case, and named in every shipped locale. `mordent` is the lower mordent and `inverted_mordent` the upper.
- A `NoteEvent` carries markings: `#articulate` and `#embellish` add articulations and ornaments by key, each at most once, and `#note_dynamic=` sets an accent such as *sfz* for that one note. A chord tone placed onto a marked note event joins it without disturbing its markings. A `RestEvent` refuses all three with `ArgumentError`.
- `HeadMusic::Content::DynamicEvent` puts a dynamic level in force at a position. `Voice#place_dynamic` places one for a voice, even under a held note or a rest, and `Part#place_dynamic` one for every voice of a part on every staff; a second at the same position raises `ArgumentError`. `Voice#dynamic_at(position)` answers the level in force from the latest of the voice's and the part's events, or *p* from an *fp* note onward.
- Flow JSON writes a voice event's `"articulations"`, `"ornaments"`, and `"note_dynamic"`, and a voice's and a part's `"dynamic_events"`, as optional keys within schema 5. A flow without markings serializes as before.
- Flow JSON writes a voice's and a part's `"spans"` as a list of `{"kind", "from", "to"}`, an optional key within schema 5, and reads a voice's back after its events, so an end its kind cannot sit on, a slur on a part, or hairpins that overlap raise `ArgumentError` naming its path. A flow without spans serializes as before.
- ABC reads and writes articulations, ornaments, and note dynamics, in shorthand (`.`, `L`, `T`, `M`, `P`), `!name!`, and `+name+` forms, and reads `!ppp!` to `!fff!` as dynamic events on the voice. It writes a voice's and its part's dynamic events before the note they fall on. Other standard decorations, such as bowings, are dropped.
- LilyPond reads and writes articulation shorthands and commands (`-.`, `-!`, `->`, `--`, `-^`), the ornaments `\trill`, `\mordent`, `\prall`, and `\turn`, the sforzandos `\sf`, `\sfz`, `\rfz`, and `\fp`, and levels from `\ppp` to `\fff` as dynamic events on the voice. It reads a `\new Dynamics` inside a `\new PianoStaff` or `\new StaffGroup`, or beside a `\new Staff`, as the part's dynamic events, giving a sforzando there to every note of the part attacking at its position, and writes a part's dynamic events that way, with spacer rests. Fermatas, arpeggios, bowings, and breath marks are dropped, as is a `\key`, `\time`, or `\clef` repeated inside a `\new Dynamics`.
- MusicXML writes articulations, ornaments, and note dynamics in `<notations>`, and each dynamic event as a `<direction>` at its position, with a `<voice>` and `<staff>` when it is a voice's.
- kern reads and writes a token's articulations (`'`, `` ` ``, `^`, `~`, `^^`), ornaments (`t`, `S`, and Humdrum's older names `m` for the upper Pralltriller and `w` for the lower mordent), and `z` (*sfz*). It reads a `**dynam` spine as dynamic events on the part of the nearest `**kern` spine to its left, giving an *sf*, *sfz*, *rfz*, or *fp* to every note of the part attacking on its row, and writes one `**dynam` spine per part that has dynamics. A dynamic that falls in the middle of a note is written on null rows spaced evenly to land on it, leaving the note whole. Text such as "cresc." is skipped.
- The ABC, LilyPond, kern, and MusicXML writers raise `RenderError` for a voice or part dynamic, or a hairpin's start or end, in a bar before or after the written music, naming it and its position, rather than leaving it out. A dynamic or hairpin start exactly where the music ends is refused; a hairpin may end there, on the final barline.
- The ABC and kern writers raise `RenderError` naming the position where a part and its voices hold different dynamic levels at one position, since an ABC voice and a part's `**dynam` spine hold one at a time, rather than writing one of them.
- `HeadMusic::Rudiment::SpanKind` is a catalog of markings that run from one point to a later one: the slur and the phrase mark (alias `phrasing_slur`), which are curves, and the crescendo (alias `cresc`) and diminuendo (aliases `decrescendo`, `decresc`, `dim`), which are hairpins. Each kind states its rules as data: its family (`#curve?`, `#hairpin?`), what its ends sit on (a slur on notes, a phrase on any voice event, a hairpin anywhere), whether it covers its last note or ends at its end position, and what may hold it (a hairpin, a voice or a part).
- `HeadMusic::Content::Span` runs from one position to a later one. `Voice#add_span(kind, from:, to:)` adds a slur, a phrase mark, or a hairpin, and `Part#add_span` a hairpin for every voice of the part, raising `ArgumentError` for an end that its kind cannot sit on, an end that does not come after the start, or the same span twice. Curves may nest or overlap; hairpins of one voice or one part may touch but not overlap, while a voice's may overlap its part's. `Voice#spans` and `Part#spans` answer their own in order, and `Voice#spans_at(position)` answers those in force there, its part's hairpins included, innermost first: a curve runs to the end of its last note, and a hairpin to its end position. A part hairpin adds no bars, and may end at `Flow#final_barline_position`.
- ABC reads and writes slurs, `(` … `)` and the dotted `.(` … `)`, as spans, pairing them by nesting as ABC does. A slur that spans a single note, closes with nothing open, or ends on a rest is dropped. The writer opens a slur before a note's decorations and closes it after the last part of its last note. ABC has no phrase mark, so a phrase is written as a slur drawn in to the notes at its ends, and left out where it would cross a slur or cover the same notes. A slur that begins where another ends starts on the note after, since ABC cannot say both on one note, and two slurs that cross raise `RenderError`.
- LilyPond reads and writes slurs `(` … `)` and phrasing slurs `\( … \)` as spans, with a `^` or `_` direction, and named with `\=` so that two may overlap, as `\=1(` … `\=1)`. A close on a tie's later link belongs to the tied note, and marks pair in the order written, so `e')( f'` ends one slur and begins the next. As in LilyPond, an open while one of its kind and name is open is ignored; an unmatched close, an unclosed open, or a slur ending on a rest is dropped. The writer opens a span after its first note's marks and closes it on the last link of its last note, closing before opening where one slur ends and the next begins, and names a slur with `\=` only when another of its kind is open, so nested and crossing slurs compile.
- MusicXML writes a voice's slurs and phrase marks as `<slur>` in `<notations>`, starting on the first note of a span's first voice event and stopping on the last note of its last, on a rest where a phrase begins or ends there. Numbers are given in document order, bar by bar and voice by voice as the part is written, so spans open at once in the file keep apart, whether they cross, sit in different hands of a grand staff, or touch on a tied note; a seventeenth open at once raises `RenderError`.
- kern reads and writes slurs `(` … `)` and phrase marks `{` … `}` as spans, nested or elided with `&` into an overlap. A close on a tie's later link belongs to the tied note, a note's closes come before its opens so one slur can end where the next begins, and a slur that opens on a grace note stays there. An unmatched mark, or a slur the voice refuses, such as one on a rest, is dropped. The writer opens a span on its first note's first tied link and closes it on its last note's last, once per chord, and elides a slur that crosses another as `&(` … `&)`.
- **Bar markings.** A `Bar` carries a closing `barline` (`:regular`, `:double`, `:final`, `:dashed`, or `:dotted`), a `rehearsal_mark` (stored as a string), `segno?` and `coda?` signs, a `fine?`, a `to_coda?`, and a `jump`: a `HeadMusic::Content::Jump` of kind `:da_capo` or `:dal_segno`, `to` `:fine`, `:coda`, or nil. `Jump.get` reads "D.S. al Coda" and its kin. A final barline at the end of the flow is implied. Flow JSON writes the new fields sparsely within schema 5.
- `Flow#performance_order` answers the bars as played, each a `PlayedBar` with its `bar`, its repeat `pass`, and its `playing` (how many times that bar has sounded). It unfolds repeats and endings, and follows a D.C. or D.S. without taking repeats again, playing each section's last ending, to the Fine or through the To Coda. A plain D.C. or D.S. stops at whichever comes first. More than one jump, a D.S. with no segno, an al Fine with no Fine, or an al Coda with no To Coda or coda sign raises `ArgumentError`.
- ABC reads and writes `||`, `|]`, and `.|` barlines, body `P:` labels and inline `[P:x]` as rehearsal marks, and the navigation decorations `!segno!`, `!coda!`, `!fine!`, `!dacoda!`, `!D.C.!`, `!D.S.!`, and the abcm2ps `!D.C.alfine!`, `!D.C.alcoda!`, `!D.S.alfine!`, and `!D.S.alcoda!`. In a tune with an al Coda jump, two `!coda!`, and no `!dacoda!`, the first coda sign is read as the To Coda. A part label, segno, or coda sign after the last note is dropped. The writer now writes repeats, `::`, and 1st and 2nd endings, closing an ending before a plain barline with `[|`.
- LilyPond reads and writes `\bar` styles, `\mark`, `\sectionLabel`, `\section`, `\segnoMark`, `\codaMark`, `\fine`, and `\jump`, and writes a final `\bar "|."`. A Fine before the last bar, or a To Coda on a jump bar, is written as `\textEndMark` in the first voice, and a coda sign beside a segno as a `\textMark` of its glyph, so the output compiles with lilypond 2.26 without warnings. As in ABC, two `\codaMark`s with an al Coda jump and no To Coda read the first as the To Coda.
- MusicXML writes `<barline>` elements with `<bar-style>`, repeats, and endings, a final `light-heavy` barline, and `<rehearsal>`, `<segno>`, `<coda>`, and words with the `<sound>` attributes for Fine, To Coda, D.C., and D.S., in every part.
- kern reads and writes `||` and `|!` barlines and `*>A` section labels as rehearsal marks, and writes `==` only at the end. Expansion lists are still ignored.
- The ABC, LilyPond, MusicXML, and kern writers raise `RenderError` for repeat structure or a marking on a bar after the music ends, rather than dropping it. `Flow#last_sounding_bar_number` answers the bar the music ends in, which the readers and writers share, and `Flow#bar(number)` answers one bar, allocating only that one.
- `HeadMusic::Notation::BarSplitter.position_at(flow, bar_number, offset)` turns an offset in a bar into a position, the inverse of `offset_in_bar`.
- ABC reads `x` invisible rests and `y` spacers, placing a level written on either at its position; an `x` that ends the voice in the bar where its music ends adds no event, and any other is read as a rest.
- ABC reads a voice overlay `&` of invisible rests and spacers, placing its levels at their positions in the bar, and raises `UnsupportedFeatureError` for an overlay holding notes or rests and for the multi-bar `(&` … `&)`, and `ParseError` for one that runs past its bar's music.
- LilyPond import reads a spacer `s` in a voice: one that ends the voice in the bar where its music ends adds no event and keeps its dynamic level at its position, and any other reads as a rest.
- LilyPond import reads `\after D mark music`, placing a dynamic level part way into a note, rest, or sequence at its exact position.
- kern import leaves out invisible rests (`ryy`) after a spine's last visible event in the bar where its music ends, so a `**dynam` level beside them keeps its position; any other invisible rest is read as a rest.
- Every writer places a voice or part dynamic at its exact position where no note starts. ABC writes one inside a note or rest on a voice overlay of invisible rests (`C4 D4 & x2 !f!x6|]`) and one after the last note of a short final bar on a trailing invisible rest (`C2 D2 E2 !f!x2|]`). LilyPond writes one inside a note with `\after` and one after the music on spacers. kern writes them on null rows and invisible rests (`ryy`), and one before a pickup's first note beside the pickup's leading rest. MusicXML writes each with an `<offset>`. ABC and LilyPond raise `RenderError` naming the position for a dynamic no binary note value reaches.
- **Hairpins in every format.** Each writer places a hairpin's start and end at its exact position, inside a note, on a tied note's later link, or on the final barline, writing at one position its ends, then its levels and accents, then its starts. Each reader drops a hairpin it cannot pair rather than raising, so every file that imported still imports.
  - ABC reads `!<(!`, `!<)!`, `!>(!`, `!>)!`, and `!crescendo(!`/`!diminuendo(!` with their closes as a voice's hairpins, pairing them by kind, and writes a voice's and its part's hairpins that way, ending one on the final barline as `!<)!y`. It refuses a voice's and its part's hairpins that overlap.
  - LilyPond reads `\<`, `\>`, `\!`, `\cresc`, `\dim`, `\decresc`, and their `\end…` forms in a voice and in a `\new Dynamics`, ending an open hairpin at a level, an accent, or the next hairpin, reads `<>` as a marker that takes no time, and skips styling commands such as `\crescTextCresc`. It writes a voice's hairpins in the voice and a part's in its `\new Dynamics`, cut where a level or accent in that context falls inside one, as LilyPond would end it there, and ends one on the final barline with `<>\!`. It also writes a voice's dynamics in a bar where the voice has only a whole-bar rest.
  - kern reads `<`, `>`, `[`, `]`, and the doubled closes `[[`/`]]` in a `**dynam` spine as the part's hairpins, pairing them as Verovio does, and writes a part's and its voices' hairpins there, cut at the levels and accents inside them, ending one on the final barline with a doubled close. It refuses hairpins of a part and its voices that overlap.
  - MusicXML writes hairpins as `<wedge>` directions, numbered in document order across a part's voices, with `<divisions>` fine enough for every start and end.
- **Tuplet ratios.** `HeadMusic::Rudiment::TupletRatio.get("3:2" | [3, 2] | "triplet")` is an unreduced actual-to-normal ratio, so 6:4 is not 3:2, with a `factor` of normal over actual; 1:1 and non-positive numbers raise `ArgumentError`. `RhythmicValue.get(identifier, tuplet:)` and `RhythmicValue.new(unit, dots:, tied_value:, tuplet:)` put a ratio on a value, each link of a tied chain carrying its own, and `#with_tuplet` puts one on every link. Values are named with the ratio first ("triplet eighth", "5:4 sixteenth", "triplet dotted eighth", "triplet eighth tied to quarter"), and `get` reads those names back, where "triplet eighth" had read as a plain eighth. A name with a tuplet word anywhere else, such as "eighth triplet" or "quintuplet eighth", is nil rather than a plain value. `#tuplet_ratio`, `#tuplet?`, and `#uniform_tuplet_ratio` answer the ratios, and `#written_fraction`, `#fraction`, `#exact_subticks`, and `#subticks` give exact lengths: a 7:4 sixteenth is 230400/7 subticks, rounded once over a chain to 32,914. `Rhythm::SUBTICKS_PER_TICK` and `SUBTICKS_PER_WHOLE` join `PPQN`, and `HeadMusic::Time::SUBTICKS_PER_TICK` is aliased to it.
- Ratios that do not land on whole subticks, such as septuplets, round each onset to the nearest subtick, measured from the start of its run of consecutive same-ratio values, so the run's span stays exact and rounding never accumulates: seven 7:4 sixteenths from the downbeat end exactly on beat 2. `VoiceEvent#onset_remainder` answers the exact onset less the position, in Rational subticks, and `Voice#voice_event_preceding(position)` the event starting last before a position.
- **Tuplet groups.** `Voice#group_tuplet(from:, to:, unit: nil)` brackets the notes and rests from one position up to an exclusive end as one `HeadMusic::Content::TupletGroup`, which tells two triplets from one sextuplet and gives the written `unit` its bracket counts in. A group brackets tied links, so it may begin or end partway through a chain; its links must be consecutive, carry one ratio, and fill its span exactly, and a group of a ratio that rounds must begin and end on voice events. Such a group may begin partway through a run of its ratio, and grouping moves no onset, so back-to-back brackets of three, seven, and four septuplet sixteenths keep the run's exact onsets and read and write as authored. Otherwise `ArgumentError` names the group ("the 3:2 tuplet from 1:1:000 to 1:2:000 …"), as it does for overlapping groups, since nested tuplets are not supported. The default unit is the written total over the ratio's actual count where that is one plain or dotted value, so a quarter and an eighth under 3:2 count in eighths, and otherwise the largest value dividing every link. `Voice#tuplets` and `#tuplet_at(position)` answer the groups, `Voice#to_h` writes them as `"tuplets"`, and `Voice#place` refuses a new event inside a group, while a chord tone or a note placed on a rest there merges as before.
- **Grace notes.** `NoteEvent#add_grace_note(sound_or_sounds, rhythmic_value, slashed: false, tied: false, articulations: [])` adds a `HeadMusic::Content::GraceNote` before the note: one or more sounds, pitched or unpitched, a plain or dotted written value, a slashed (acciaccatura) or unslashed (appoggiatura) flag, a tie to whatever follows, and articulations. `NoteEvent#grace_notes` answers them in order, and a note keeps them when another sound is merged into it. Grace notes take no time and are never voice events, so positions, bars, continuity, melodic and harmonic analysis, and every guide pass them by. A `RestEvent` refuses one with `ArgumentError`. `Voice#add_span(kind, from:, to:, from_grace: true)` starts a slur or phrase on the first grace note of the note at `from`, and may end on that same note; a hairpin, a note without grace notes, or a part's span refuses it.
- Flow JSON writes tuplets and grace notes as optional keys within schema 5, and documents without them read as before. A ratio is written inside a value's `"rhythmic_value"` name (`"triplet eighth"`, `"7:4 sixteenth"`), a voice's groups as `"tuplets"`, a list of `{"from", "to", "unit"}` read back after its events, a note's grace notes as `"grace_notes"`, each `{"sounds", "rhythmic_value", "slashed"?, "tied"?, "articulations"?}`, and a span from grace notes with `"from_grace": true`. A bad group, grace note, or flag raises `ArgumentError` naming its path, such as `parts[0].voices[0].tuplets[2]` or `parts[0].voices[0].voice_events[3].grace_notes[1]`, as do grace notes on a rest. Since schema 5 first ships in 23.0.0 and 22.x reads only schema 4, no released gem misreads them.
- `DottedDuration.sounding_fraction(link)` answers a link's length under its tuplet ratio, beside `dotted_unit_fraction`, its written length, and `rhythmic_value_for(fraction, tuplet:)` builds a value under a ratio from its sounding length. `BarSplitter.onset_in_bar(voice_event)` answers a voice event's exact onset in its bar, and `BarSplitter.segments_of` cuts at exact onsets and lengths, so a tuplet note crossing a barline splits into tied notes of its ratio, a rounded septuplet at the exact barline, and a chain of mixed ratios link by link. Each `Segment` carries its exact `offset` in its bar and the fraction `elapsed` before it. A piece that cannot be written under its ratio, such as a 2:3 duplet across a 6/8 barline, raises the writer's `RenderError` naming the group or the ratio.
- `HeadMusic::Notation::TupletBrackets.for(voice, segments)` answers the tuplet brackets a writer draws over a voice's bar segments, each a `Bracket` with its `ratio`, `unit`, written `links`, and `group`: one per tuplet group, across a barline where the group crosses one, and one per run of ungrouped values of a ratio, closing once its written total reaches the ratio's actual count of its shortest unit and counted in a group's default unit. The ABC, LilyPond, kern, and MusicXML writers raise `RenderError` for a dynamic or hairpin end strictly inside a note of a ratio that does not land on whole subticks, such as a septuplet, where no note starts, naming the mark and the note, since no exact time can be written for it.
- **Tuplets and grace notes in every format.** Each reader reads them, and each writer writes them, with written durations taken from a value and its ratio, never from its rounded ticks. Every file that imported still imports.
  - ABC reads `(3`, `(p:q:r`, and the meter-dependent default for `(n` as tuplet groups, and `{…}` and `{/…}` as grace notes before the next note, with a slur opened before the braces starting on the first of them. It writes groups, and runs of tuplet values with no group, as `(p:q:r`, or the short `(3` and `(2` where they mean the same thing, and grace notes as `{…}` and `{/…}`. A tuplet inside another raises `UnsupportedFeatureError`, and a tuplet across a barline raises `RenderError` naming the group.
  - LilyPond reads `\tuplet n/d { … }`, its span form `\tuplet n/d dur { … }`, `\tupletSpan`, and `\times d/n { … }` as tuplet groups, and `\grace`, `\slashedGrace`, `\appoggiatura`, and `\acciaccatura` as grace notes, with the slur the last two imply. `\afterGrace`, and grace notes before a rest, skip their grace notes. Nested tuplets, and `R` or `<< >>` inside a tuplet, raise `UnsupportedFeatureError`. It writes one `\tuplet n/d { … }` per group and per run of ungrouped values, across barlines where a group crosses one, and `\acciaccatura` or `\appoggiatura` for grace notes slurred to their main note, `\slashedGrace` or `\grace` otherwise. Spacers that fall between subticks, such as `s1*1/28` beside a septuplet, round to the nearest subtick instead of raising.
  - kern reads a duration whose undotted value has a non-power-of-two denominator as a tuplet value, with actual the odd factor of the denominator and normal the largest such count below it (`12` a triplet eighth, `24` a triplet sixteenth, `20` a 5:4 sixteenth, `28` a 7:4 sixteenth, `3%2` a triplet whole); duplets read as dotted values, and nested tuplets as their one flattened ratio. It infers a group from the first run of at least two consecutive values of one ratio whose exact length is a plain note value, across barlines, so a sextuplet reads back as two triplets. It infers link by link, so a group may end or begin inside a tied chain that mixes ratios, as a triplet ending in a triplet eighth tied to a quarter. It reads `q` as slashed grace notes and `Q` or `qq` as unslashed ones, keeping their articulations, a tie into the note, and a slur or phrase that opens on the first of them, and drops grace notes before a rest, a tie's later link, or the end of a spine. It writes tuplet values as reciprocals of what they sound (`12`, `12.`, `28`), a value whose length is a plain or dotted note as that note (duplets as `8.`), and `%` otherwise (`10%3`), and grace notes as `q` and `Q` tokens on rows of their own.
  - MusicXML writes `<time-modification>` on every tuplet note, `<tuplet type="start">` and `<tuplet type="stop">` on the ends of each group or run, across barlines too, and grace notes as `<grace/>` notes, `<grace slash="yes"/>` for acciaccaturas, with their ties, articulations, and slurs. `<duration>` is the exact sounding length, and `<divisions>` are computed from written values and ratios, so septuplets are exact too.
- `DottedDuration.tuplet_ratio(fraction)` infers the ratio a non-binary length sounds under, and `DottedDuration.rest_value(fraction)` answers the rest that fills a length, under that ratio where no plain value does; kern now uses them. `TupletGroup::Link#start_position` and `#end_position` answer where a link of a tied chain starts and ends.
- The MusicXML writer writes a `<part-symbol>` for a multi-staff part joined by a bracket or by nothing, leaving a brace to its default.
- The MusicXML writer writes a part's instrument as `<score-instrument>` with its W3C standard `<instrument-sound>`, from a table (`MusicXML::InstrumentSounds`) of about 120 sound ids the reader shares. `MusicXML::KeyMapper.tonal_context(fifths, mode)` reads a `<key>` back as the key or mode the writer wrote, and `MusicXML::MarkingElements` maps articulation, ornament, and accent elements both ways.
- **MusicXML import.** `MusicXML::Parser` reads a score-partwise or score-timewise document with REXML, in UTF-8 with or without a byte order mark, UTF-16 with one, or a binary string, and raises `MusicXML::ParseError` naming the line of malformed XML; `MusicXML::UnsupportedFeatureError` names a compressed `.mxl` as a follow-up. `MusicXML::ParsePreflight` refuses a document that declares entities, and text past REXML's expansion limits raises `ParseError` rather than a bare `RuntimeError`. The DTD is never fetched. `MusicXML::Document` regroups a timewise score's measures into parts.
- `HeadMusic::Notation::MusicXML.parse(string)` returns a `Flow`. It reads notes and rests from `<pitch>`, `<type>`, `<dot>`, and `<duration>` at the `<divisions>` in force, ignoring a `<duration>` within one division of its written value as exporter rounding and raising `ParseError` naming the measure beyond that, or for a `<duration>` with no `<divisions>` in force; a note with no `<type>` takes its value from its `<duration>`. A `<divisions>`, `<staves>`, `<beats>`, or `<beat-type>` that is empty or not positive, a number written with an exponent, and a `<note>` with no `<pitch>`, `<unpitched>`, or `<rest>` raise `ParseError`, and a pitch outside octaves -1 to 9 or altered past a double sharp or flat, as written or once transposed, raises `UnsupportedFeatureError`, each naming the measure. The `<movement-title>` names the flow, with the `<work-title>` beside it as its `Work`, and a `<work-title>` alone, or failing that a title `<credit>`, names it; composer `<creator>`s become the composer, credited on the `Work` where there is one; each `<part-name>` names a `Player` with no project; and a mapped `<instrument-sound>` gives the part its instrument.
- MusicXML import aligns every part's measures into bars: an implicit first measure is a pickup in bar 0, a short first measure is right-aligned in its bar, a short measure the next one completes is one bar with it, whether or not the next is marked implicit, unless it changes the meter, and a short final bar reads as written; an overfull measure, any other short measure, a meter of added beats such as 3+2/8, and a beat type that names no note value, such as 3/3, raise `UnsupportedFeatureError` naming the measure. A whole-measure rest, `measure="yes"` or as long as the meter, fills its bar. `<key>` (`<fifths>` and `<mode>`), `<time>`, and `<sound tempo>` open the flow and change it at later barlines, the first part's key winning; a key, time, or tempo in the middle of a bar is skipped, while a `<divisions>` change applies from its point on.
- MusicXML import reads each `<voice>` value of a part as a voice, in order of first appearance, a note with none being voice 1; `<backup>` and `<forward>` move the cursor, one of no duration moving nothing, a `<forward>` gap becomes a rest, and every voice is padded with rests split at barlines from the first bar to the end of the music, parts with fewer measures included. `<chord/>` adds a tone to the note before it, cue notes read as rests of their length, a note or rest that does not print (`print-object="no"`) takes its time as a `<forward>` does, with its chord tones and grace notes, and `<unpitched>` notes as unpitched sounds of the part's instrument, or of none. A `<multiple-rest>` is skipped. A `<backup>` before the start of its measure, a `<chord/>` with no note before it in its voice, and a voice that overlaps itself raise `ParseError`, and chord tones of different lengths and a `<measure-repeat>` raise `UnsupportedFeatureError`, each naming the measure.
- MusicXML import folds tied notes into one voice event, across barlines, keeping each link's written value: `<tie>`, falling back to `<tied>`, where `<tie>` wins when they disagree and `let-ring` and `continue` are skipped. A tie that nothing stops, that a rest follows, or whose stop does not start where the note before it ends, within one division, is dropped and its note keeps its written value; a tie on only some pitches of a chord, or between chords that share only some pitches, is skipped; and a tie between pitches that share nothing raises `ParseError` naming the measure it starts in.
- MusicXML import reads `<time-modification>` as tuplet values and `<tuplet>` starts and stops as tuplet groups, link by link, so a bracket may end on the first piece of a tied note, with the `<normal-type>` as the group's unit. A run with no `<tuplet>`, an unmatched start or stop, or a bracket the voice refuses stays ungrouped with its ratios kept, and a start is abandoned once its run of one ratio ends; a start inside a bracket's run, its ratio the run's or a multiple of it, raises `UnsupportedFeatureError` for nested tuplets.
- MusicXML import reads `<grace>` notes as grace notes of their voice's next main note, slashed for `slash="yes"`, a grace chord as one grace note with several pitches, an eighth where there is no `<type>`, with their articulations, and tied where a tie starts on a pitch what follows shares; a tie into the main note takes the place of its stop. Grace notes before a rest, a tie's later link, or the end of the part are dropped.
- MusicXML import builds a part's staff system from `<staves>`, joined as its `<part-symbol>` says (`bracket` and `square` as a bracket, `none` as none) and otherwise braced as `StaffSystem.grand_staff` is, with each staff's clef from `<clef>`, and assigns each voice to the `<staff>` of its first note in each bar, so a change at a barline is a staff crossing; a change in the middle of a bar is skipped. A later clef on a downbeat is a clef change, `<clef-octave-change>` reads octave clefs, and percussion and TAB clefs read as no clef. A `<staff>` below 1 or beyond the part's `<staves>` raises `ParseError` naming the measure.
- MusicXML import honors `<transpose>` (`<diatonic>`, `<chromatic>`, `<octave-change>`), so a transposing part's notes, grace notes, and key land in concert pitch, a later `<transpose>` replacing the one before it, as after an instrument change; a numbered `<transpose>` applies to its staff alone. `<double>` is skipped.
- MusicXML import runs a registry of mark readers (`MusicXML::MARK_READERS`, each a `MusicXML::MarkReader`) once every voice is final, handing them a `NoteRecord` for each `<note>`, a `DirectionRecord` for each `<direction>` and measure-level `<sound>`, and a `BarlineRecord` for each `<barline>`, in document order, then having each apply what it read. The core reads in linear time: doubling a document's bars at most doubles the positions it builds and the meters it looks up, and it places every voice in order, so none is revised.
- MusicXML import reads articulations, ornaments, and note dynamics in `<notations>`, and a `<direction>` accent onto the note attacked at its position.
- MusicXML import reads lyrics: verses by `number`, unnumbered as verse 1 and other labels ranked by first appearance, `<syllabic>` hyphenation, and elisions.
- MusicXML import reads `<slur>`s as slurs, paired by number, and as phrase marks where either end falls on a rest, including slurs from grace notes; an unmatched slur is dropped.
- MusicXML import reads `<beam>`s as beam breaks where they differ from the default grouping, so the writer's beams round-trip.
- MusicXML import reads barline styles, repeats, and 1st and 2nd endings, including ending number lists such as "1, 2". A repeat with no `times` plays as often as its section's highest ending.
- MusicXML import reads rehearsal marks, segno and coda signs, Fine, To Coda, D.C., and D.S., letting their `<sound>` attributes decide over the words, and reads MuseScore's segno and coda glyph words (U+E047, U+E048) as the signs.
- MusicXML import reads `<direction>` dynamics as dynamic events at their `<offset>`, on the voice `<voice>` names or the part, and pairs `<wedge>`s by number into hairpins in document order; a stop with no open wedge waits for a later start of its number that sounds before it, as MuseScore writes them, and unmatched wedges are dropped.
- `Instrument#gm_program` answers the nearest General MIDI program, 1-based as GM tables print it, and `Instrument#gm_percussion_key` the nearest GM percussion key (35–81) for unpitched percussion. A variant such as `clarinet_in_a` inherits its parent's. Didgeridoo, theremin, and tabla have no program, and the drum kit and castanets no percussion key; the tam-tam stands in as the Chinese Cymbal (52) and the tenor drum as the Low Tom (45).
- **MIDI export.** `HeadMusic::MIDI.render(flow, transposed: false)` and `Flow#to_midi` write a format 1 Standard MIDI File as a binary string: a conductor track with the sequence name and the meter, tempo, and key in force at each played bar wherever they change, then one named track per part. Bars play in `Flow#performance_order`, a pickup starts the file at its first note, a tie over a barline sounds on only into the next bar of the score, and a key struck again on its channel while it sounds is released and re-struck. Pitched parts take channels in part order around channel 10, sharing one where they play the same instrument throughout. The ticks per quarter are the least common multiple of 480 and every time written, or 960 with rounding past what a division holds. `MIDI::RenderError`, a subclass of `Notation::RenderError` so one rescue covers every writer, is raised before any bytes are written for an empty flow, a broken navigation such as a D.S. with no segno, a flow name, track name, or lyric that is not valid UTF-8, a meter whose click a MIDI time signature cannot count (6/1, 9/1, 12/1, and denominators of 64 or more), a performance longer than MIDI's delta times hold, a key outside 0..127, a meter or tempo MIDI cannot hold, and more than fifteen distinct pitched channels.
  - Velocities follow the dynamic level in force, from `HeadMusic::MIDI::VELOCITIES` (*ppp* 16 to *fff* 127, *mf* 80 by default), raised by accents and marcatos (`ARTICULATION_BOOSTS`) and by *sf*, *sfz*, and *rfz* (`NOTE_DYNAMIC_BOOSTS`), and clamped to 1..127. An *fp* note strikes at *f*. Under a voice or part hairpin, velocities ramp by onset to the level placed at its end, or one level beyond its start, which stays in force after it; the innermost hairpin governs, a voice's over its part's.
  - Grace notes sound on the beat, taking their time from the main note, and a grace note tied to its main note holds through it. Staccatissimo, staccato, and portato notes sound for a quarter, half, and three quarters of their last tied link, staccatissimo winning over the others.
  - Each pitched part writes its instrument's General MIDI program at its start and at every instrument change, restored by repeats and D.C., or 1 (Acoustic Grand Piano) when the instrument has none. Unpitched sounds play on channel 10 at their instrument's GM percussion key, else `DEFAULT_PERCUSSION_KEY` (76, Hi Wood Block), even within a pitched part's track.
  - With `transposed: true`, each pitch is read as written and sounds at its written pitch plus the sounding transposition of its part's instrument in force at its bar; the key signature stays concert.
  - Each sung syllable writes a UTF-8 lyric meta event at its note's onset, with "-" when the word continues. Pass *n* of a repeat sings verse *n* where the flow has one, else verse 1, and the first voice of a part with a syllable wins when two sing at once.
  - A pickup shorter than a count writes the time signature that holds it exactly, such as 1/8 then 3/4 for an eighth pickup in 3/4, or the flow's meter restated at bar 1 where no such signature exists. A part with no instrument writes no program change; one that loses its instrument after having one writes program 1, so a repeat back past the change cannot replay a stale program.
- **MEI export.** `HeadMusic::Notation::MEI.render(flow, **options)`, `Flow#to_mei`, and `Layout#to_mei` write MEI 5.1 documents, generated as text with no new dependency, and valid against `mei-CMN.rng`. `MEI::RenderError` is raised before anything is written for an empty flow, unpitched sounds, text XML cannot hold, or a part whose staff system changes.
  - The `<meiHead>` carries the title (the layout's, the Work's, or the flow's name) and one `<persName role>` per credited person; each flow is an `<mdiv label>`. Every element from `<mdiv>` down has an `xml:id` built from its part, voice, bar, and onset, so the same flow always gives the same ids.
  - Multi-staff parts are nested `<staffGrp symbol>`s labeled with the player; each staff carries its clef and General MIDI `<instrDef>`, each voice with a role a `<layerDef>`, and a voice keeps its `<layer n>` when it crosses staves.
  - Notes carry `@pname`, `@oct`, `@dur`, and `@dots`, with `@accid` where the key and earlier notes in the bar on that staff do not imply the pitch and `@accid.ges` otherwise. Rests, whole-bar `<mRest>`s (also for a voice with nothing in a bar), chords, and `@tie` follow; a pickup is `<measure n="0" type="upbeat">` and an underfull final bar carries `metcon="false"`. Beams are `<beam>` groups from the grouping MusicXML uses, tuplets `<tuplet>`s nesting with them, with `<beamSpan>` and `<tupletSpan>` where they cannot nest, and grace notes carry `@grace`.
  - Key, meter, clef, and instrument changes are `<scoreDef>` and `<staffDef>` before their measure, and tempo changes are `<tempo>` with `@midi.bpm`, the opening tempo being `scoreDef/@midi.bpm` alone. With `transposed: true`, transposing staves carry their written `@keysig` and `@trans.diat`/`@trans.semi`, reset to 0 when a part returns to an instrument in C.
  - Articulations are `@artic`; trills, mordents, turns, and note dynamics are control events at their note; dynamic levels and hairpins sit at their `@tstamp`, with `@layer` for a voice's; slurs and phrase marks point at their notes by `@startid` and `@endid`.
  - Barline styles, repeats, and endings are `measure/@left`, `@right`, and `<ending n label>`; rehearsal marks are `<reh>`; segno, coda, Fine, To Coda, D.C., and D.S. are `<repeatMark @func>`; a repeat played more than twice gets a `<dir>` "×N"; and lyrics are `<verse n><syl>` with `@wordpos` and `@con`.
- **MIDI import.** `HeadMusic::MIDI.parse(bytes, key: nil, grid: :auto)` reads a Standard MIDI File of format 0 or 1 as a flow: a part per track and channel, voices and chords, meter, tempo, key, instrument changes, percussion on channel 10, and lyrics. All 366 readable Bach chorales come back note for note through MIDI export and import, spelled 99.947% as written with `key: :infer`.
  - `HeadMusic::MIDI::Reader`, now part of the gem, decodes the file's tracks of timed events and pairs notes per channel and key across tracks. It tolerates what real files do (a longer `MThd`, extra tracks, a missing end-of-track, running status after meta events, Windows-1252 text). `MIDI::ParseError` names the byte offset of anything malformed, and `MIDI::UnsupportedFeatureError` covers format 2, SMPTE time division, and denominators above 64. Files needing more than 200,000 notes, 10,000 bars, 128 parts, or 1,000,000 voice-bars are refused before any flow is built, and a part needing more than 64 voices raises `UnsupportedFeatureError`.
  - Bars come from the time signatures, a short first bar reading as a pickup; a meter change within a bar raises. Tempo is taken at each downbeat and restated in the meter's beat. Key signatures apply at the downbeat; with none, or with `key: :infer`, the key is found by `KeyFinder`, and every note is spelled by `PitchSpeller` with its voice. `key:` also takes a key, a key name, or key regions, which spell the notes while the file's signatures stay. Unknown options or values raise `ArgumentError`.
  - The grid is the coarsest of sixteenths, thirty-seconds, sixty-fourths, and their triplets that places every onset within a tick, or failing that the coarsest within 99% of the best; `grid:` takes one of these or any Rational down to 1/256, the finest value the model can write. A release just short of the next onset extends to it. Notes are tied chains cut at barlines, and at beats where a value is not binary, with triplets as 3:2 tuplets; rests are cut at beats and aligned to their own length.
  - Notes that start and end together form chords, and overlapping notes separate into voices by nearest mean key number, deterministically.
  - GM programs map to catalog instruments, through a pinned table where several share a program and through the track name where it names one; percussion keys map to unpitched sounds, with aliases for the common drum-kit keys. A track name becomes the player unless it is exactly the instrument's name, and track 0's name names the flow when that track holds no notes.
  - Lyric meta events sing on the notes they fall on, with hyphens, and with successive verses at one onset.
  - What MIDI cannot carry comes back as it can: modes as major keys (a MIDI key signature holds only major or minor), legacy-encoded text as Windows-1252, and drum keys sharing one sound as one note.
- `PitchSpeller::Respelling.signature_changes(regions)` answers the regions whose key signature differs from the one before.
- **Key and spelling inference.** `HeadMusic::Analysis::KeyFinder` infers the key of music given only key numbers and timing, and `HeadMusic::Analysis::PitchSpeller` spells each key number as a pitch in that key, so music that arrives unspelled, such as MIDI, becomes readable notation. On the Bach chorales, spelling matches the written notes 99.95% of the time, whether the key is given or inferred.
  - Input: both take `NoteInput`, which reads `[number, onset, duration, voice]` tuples (with `"bar:count"` onsets when a `meter:` is given), `UnspelledNote`s, or a flow, with `bars:` and `first_bar:` for meter changes and pickups.
  - `KeyFinder#key` answers the major or minor key whose profile correlates best with the duration-weighted pitch-class profile, and `#candidates` ranks all 24. `KeyProfile` offers Aarden–Essen (the default), Krumhansl–Kessler, and Temperley (2007), each with its source. `#regions` answers key regions beginning at downbeats, found over the bars with a `change_penalty:` for each change; a later region's tonic takes the enharmonic nearer the one before.
  - `PitchSpeller` spells by a key, a mode, or key regions, inferring them when none is given. It spells notes in the key's collection, and a minor key's raised 6th and 7th, from the key. Near ties go by melodic direction, then by keeping a sonority compact on the line of fifths, then by the key's center (Temperley 2001, Meredith 2006). `#spelled_notes` reports the rule that decided each note.
  - `PitchSpeller.respell(flow, key:)` returns a respelled copy of a flow: by the key signatures in force, or with `key: :infer`, under inferred key signatures. The flow passed in is unchanged.
  - `HeadMusic::Analysis::LineOfFifths` places spellings on the line of fifths.
- **MEI import.** `HeadMusic::Notation::MEI.parse(string)` reads the one movement (leaf `<mdiv>`) of an MEI document into a `Flow`, and `MEI.parse_book` reads one flow per movement with music, through nested `<mdiv>`s, `<group>`s, and `<meiCorpus>`. It reads MEI 5 and MEI 4 alike, whatever `@meiversion` says, and never reads an incipit in the header. `MEI::ParseError` names the element and measure; `MEI::UnsupportedFeatureError` covers mensural, neume, and tablature notation, measure repeats, microtones, nested tuplets, and staves added mid-piece. No other error escapes, with every attribute bounded and typed, `@copyof` expanded under a cycle guard and budget, entities refused, and nesting capped at 256.
  - Identity: the flow is named by `mdiv/@label` or the head title, a `Work` (with catalog number, year, and composers' dates) comes from `<workList>`, players from staff and staff-group labels, and instruments from `<instrDef @label>` or, failing that, the General MIDI program.
  - Parts, staves, and voices: a labeled or braced `<staffGrp>` is one multi-staff part, voices are keyed by layer number within a part (or by staff and layer where numbers repeat across staves), a layer whose notes share an `@staff` crosses staves at the barline, and a voice's leading and trailing whole-bar rests are not placed, so tacet voices round-trip.
  - Notes and rhythms: pitches, gestural and written accidentals (otherwise the key and earlier accidentals on that staff decide), rests, chords, and lengths from `@dur`, its chord, `@dur.default`, or the time a layer or meter leaves. Ties come from `@tie` and `<tie>`, tuplets from `<tuplet>`, `<tupletSpan>`, and `@tuplet`, beams from `<beam>`, `<beamSpan>`, and `@beam`, grace notes from `@grace` and `<graceGrp>`, and tremolos read as their notes.
  - Timeline: keys and modes, meters, tempos, clef changes, and `@trans.*` transpositions (read into concert pitch), from `<scoreDef>` and `<staffDef>` at the opening and at later measures. Control events placed by `@tstamp` snap to the nearest onset within 1/1000 beat.
  - Markings: articulations, trills, mordents, turns, dynamic levels and note dynamics, hairpins, slurs and phrase marks, barlines, repeats, endings, rehearsal marks, and navigation, through a registry of mark readers (`MEI::MARK_READERS`) fed by event, control, and measure records.
  - Lyrics: `<verse>/<syl>`, bare `<syl>`, and `@syl`, by verse, with hyphens and elisions. Editorial markup follows a fixed rule: `<lem>`, then `<corr>`, `<reg>`, `<expan>`, and `<add>`.
  - Every MEI Export golden, fixture, and generated seed round-trips, MuseScore 4's MEI exports and two Bach editions from the music-encoding sample encodings read, and the sample encodings sweep reads 84 of 167 files in each MEI version against a manifest of refusals. A new `mei:musescore_fixtures` rake task regenerates the MuseScore exports.
- MEI export writes `<instrDef label>` with the instrument's name key, `@key.mode` on key signatures, and a `<workList>` with each flow's `Work`, its catalog number, year, and composers, so MEI import reads them back.
- `HeadMusic::Notation::XmlReading` and `HeadMusic::Notation::ParsePreflight` are shared by the MusicXML and MEI readers.
- `HeadMusic::Notation::BeamGroups` holds the beam grouping MusicXML and MEI share, and `HeadMusic::Notation::WrittenLinks` the written pieces of a voice's segments, which tuplet brackets and beams both read.
- `Position.for_flow` builds a position in a flow from a code or keeps one of that flow's, raising for another flow's. `Dynamic.fetch` answers a dynamic of the kind asked for, `Clef.placing` the clef that puts a pitch on a line, `GraceNote#tied_pitches` the pitches a grace note ties into, and `Notation::BarMap#downbeat_bar` the bar a measure starts on its downbeat.
- `HeadMusic::Notation::LineParseError` carries the line number and snippet that the ABC, kern, and LilyPond `ParseError`s report, and each now subclasses it. `HeadMusic::Notation::TimelineReading` holds the timeline reading the MusicXML and MEI readers share, and `HeadMusic::Time::ChangeMap` the change bookkeeping of `MeterMap` and `TempoMap`.
- `HeadMusic::Content::ChainLink` is one link of a voice event's tied chain, found with `ChainLink.of(voice_event)` and `ChainLink.between(voice, from, to)`; `TupletGroup.links_of` and `.links_between` delegate to it. `NoteEvent#add_grace_notes` adds `GraceNote`s already built.
- `Position.get(flow, position)` keeps a position or builds one from a code, `Position#ending_bar_number` answers the bar music ending there ends in, `VoiceEvent#bar_number` the bar an event starts in, `DottedDuration.tied` ties a list of rhythmic values in order, and a guideline's `count_values` builds the count and number-word values its templates take.
- **Meter symbols.** `Meter.common_time` carries `Meter#symbol` `:common`, and `Meter.cut_time` `:cut`; a meter named by its numerals has none. A meter with a symbol still equals its numeric meter and calculates as it, and `Meter.common_time.to_s` is still `"4/4"`. `Meter.for_symbol(:common)` or `(:cut)` answers the meter for a symbol and raises `ArgumentError` for anything else, as `Meter.new` does for a symbol that disagrees with its numerals. A flow keeps the symbol through `Flow.new(meter:)` and `#change_meter`, and Flow JSON writes it as `"meter_symbol"` beside the opening `"meter"` and as `"symbol"` in each meter change, leaving either out where there is none; a symbol that disagrees with its numerals raises `ArgumentError` naming its path.
- **Tempo words.** `Tempo.new(beat_value, beats_per_minute, text: nil, metronome_mark: true)` carries the words a tempo was written with, and `metronome_mark: false` records that its number was not written, though `beats_per_minute` always answers one so that time can be kept. `Tempo.for_text(text)` answers a tempo for free tempo text, with the defaults of the longest named tempo the text contains as whole words ("Allegro ma non troppo" is an allegro), or else ♩=120, and `metronome_mark: false`; blank text raises `ArgumentError`. Flow JSON writes a tempo's `"text"`, and `"metronome_mark": false`, only where they differ from the defaults, and two tempos that differ only in text are different tempo changes. `Time::TempoEvent.new` takes a `Tempo` in place of a beat value and beats per minute, and it and `Time::TempoMap` keep a `Tempo` they are given rather than rebuilding it from its numbers.
- **Tempo ramps and fermatas in the `Conductor`.** `Time::TempoRamp` runs from one position to a later one toward a target tempo, with optional text, linear in beats per minute over musical position, and in whole notes per minute between different beat values; with no target it ramps to ×3/4 of its start, or ×4/3 for accel., accelerando, and stringendo. `Time::Fermata` holds a span with a `stretch`, `Fermata::DEFAULT_STRETCH` being 2, and `Time::ATempo` marks a return to the tempo before a ramp. `Conductor.new` takes `tempo_ramps:` and `fermatas:`, and converts positions to clock time through them in closed form and clock time back to positions: a 4/4 bar ramping from ♩=120 to ♩=80 lasts 2.432790649 s, a fermata multiplies its span's clock time by its stretch, and a clock time inside it maps back into its span. `Conductor#tempo_at(position)` answers the tempo sounding there, interpolated inside a ramp and held through a fermata. A ramp ending where it begins, a target of no beats per minute, or a stretch below 1 raises `ArgumentError`.
- **Tempo ramps, "a tempo", and fermatas on a flow.** `Flow#add_tempo_ramp(from:, to:, to_tempo: nil, text: nil)` adds a ramp between two positions, which may fall in the middle of a bar; `#add_a_tempo(position, text: "a tempo")` restores the tempo in force at the start of the latest ramp before it; and `#add_fermata(position, span, stretch: 2)` holds a rhythmic value's span from a position, or `#add_fermata(position, to:)` runs to a later one. Each takes positions or codes for them and allocates the bars it reaches. `#remove_tempo_ramp`, `#remove_a_tempo`, and `#remove_fermata` remove one by its start, and `#tempo_ramps`, `#a_tempos`, and `#fermatas` list them in order. Overlapping ramps, overlapping fermatas, a tempo change or an "a tempo" strictly inside a ramp, and a meter change that would leave one of them on a count its bar no longer has raise `ArgumentError`; ramps and fermatas may touch, a fermata may fall inside a ramp, and a tempo change may sit at a ramp's start or end.
- `Flow#tempo_at(bar)` answers the tempo as written: in a bar that begins inside a ramp, the tempo at its start; at or after its end, its target, which with none written is the tempo change there, or else ×3/4 of the start (×4/3 for accel., accelerando, and stringendo) with `metronome_mark: false`; and after an "a tempo", the tempo it restores. A fermata leaves it unchanged. `Flow#sounding_tempo_at(position)` answers the tempo sounding there, interpolated inside a ramp.
- `Flow#conductor` answers a `Conductor` built from the flow's meters, tempos, ramps, "a tempo" points, and fermatas, with clock zero at the downbeat of the earliest bar, pickup included. Ramp targets and "a tempo" points become tempo events, and a tempo change wins where it shares a position with one.
- Flow JSON writes the timeline's `"tempo_ramps"` (`{"from", "to", "tempo", "text"}`, leaving out a target or text that was not written), `"a_tempos"` (`{"position", "text"}`), and `"fermatas"` (`{"from", "to", "stretch"}`) as lists, empty when there are none. They are optional within schema 5: a document without them reads with none, and they are read after the meter changes, raising `ArgumentError` naming their path.
- MIDI writes tempo steps through ramps and fermatas, and reads ramps and fermatas back. `MIDI::TempoSteps` steps the tempo at each downbeat, at each count under a ramp at the average rate over the step, so the file's clock keeps time with `Flow#conductor` at every step, at both ends of every ramp and fermata, and at each "a tempo"; under a fermata the tempo is divided by its stretch and restored at its end, even at the end of the piece. Each pass through a repeat or jump writes its bars' steps again, so a jump into a ramp resumes at the tempo sounding there, and preflight refuses a step MIDI cannot hold, naming its position. A flow with no ramps or fermatas writes the same bytes as before. On import, a slower tempo restored to the one before within one bar is a fermata, its stretch read to three decimals; a run of at least two changes within bars, all faster or all slower, that settles into a tempo held until the next downbeat is a ramp to that tempo, marked "rit." or "accel."; and a change within a bar back to the tempo the latest ramp began from is an "a tempo". Other changes within a bar are still skipped.
- ABC reads and writes tempos and the timeline's fermatas, ramps, and "a tempo" points. It reads `Q:` in the header, as an inline `[Q:…]`, or as a body line: `1/4=120`, `3/8=60`, quoted tempo text before or after the number or alone, and the legacy `Q:120` and `Q:C=120` in unit note lengths; beats that no single note value spans keep only the text. It reads `H`, `!fermata!`, `+fermata+`, and `!invertedfermata!` on notes, chords, and rests as timeline fermatas, from a tie's later link where one is written there and on the event before a bar line where one stands there, and reads "rit.", "rall.", "accel.", "a tempo", and their kin from `"^…"`, `"_…"`, `"<…"`, `">…"`, and `"@x,y…"` annotations as ramps and "a tempo" points, dropping other annotation text; chord symbols still raise. It writes `M:C` and `M:C|`, the opening tempo as `Q:` unless it is ♩=120, each tempo change and ramp target as `[Q:…]` where a note starts or on the final barline, each ramp's text and each "a tempo" as a `"^…"` annotation, and `!fermata!` on the note or rest where each fermata begins. `Notation::FermataMarks`, `Notation::TempoMarkReading`, and `Notation::TempoMarks` hold the reading and writing rules every format shares, and the writers' preflight checks cover fermatas, ramps, and "a tempo" points. The ABC writer raises `RenderError` for a fractional tempo, text holding a double quote, a `[Q:…]` where no note starts, and a ramp that would not read back as written: one whose text is no ramp word, one with a fermata beginning inside it, and one with no target ending where no tempo, "a tempo", ramp, fermata, or the end of the music would end it.
- ABC reads meter changes after the opening, from a body `M:` line or an inline `[M:…]` field, `C` and `C|` included, so `[M:C]` after `M:4/4` changes only the symbol. A field in any one voice changes the flow's meter at its bar, and the voices are read together so every voice's music in that bar is placed in the new meter. The first field read for a bar wins, one that restates the meter in force makes no change, and one partway through a bar takes effect at the next downbeat. A tuplet's default count follows the meter of its bar.
- ABC reads key changes after the opening, from a body `K:` line or an inline `[K:…]` field, by the same rules as meter changes: a field in any one voice changes the flow's key at its bar, the first read for a bar wins, a restatement of the same signature and name makes no change, and one partway through a bar changes the flow at the next downbeat. A voice spells its notes in a key it states from that point on, even partway through a bar or where the flow kept another voice's key, until the flow's key changes at a later bar; the other voices spell in the flow's key. A field holding only terms such as `clef=bass` changes nothing.
- ABC writes each meter change and key change as an inline `[M:…]` or `[K:…]` field opening its bar, after any volta and part label, `[M:C]` and `[M:C|]` included, and spells each bar's notes in the key in force there, so a note tied into a change reads back at its pitch. It raises `RenderError` only for a change at a bar where no voice sounds, where it had refused every change after the opening. `RenderPlan#measure_key_at` answers the key in force in a part at a bar.
- ABC writes every voice of a flow. Each is declared with a `V:` field before `K:`, named for its role where the role holds no space, `]`, `%`, or `=` and no other voice has it, and otherwise by its place in the flow, and the voices' lines are written in turn, four bars at a time, as a score is laid out in systems. Every voice writes every bar: one it is silent in, before it enters or after it ends, is written as whole-bar rests, and the bar where it ends early is filled with them, so each reads back as rests. Bar lines, repeats, voltas, and meter and key changes are written in every voice; tempo marks, ramps, "a tempo" points, part labels, and navigation in the first voice only; a part's dynamics and hairpins in its first voice; and a timeline fermata on every voice's note sounding where it begins. A flow of one voice is written as before, with no `V:` field. `RenderPlan#lead?`, `#music_end`, `#music_end_fraction`, and `#fermata_carriers` are shared by every format's plan.
- Transposed ABC output writes each voice in its own part's written key, and a part that picks up an instrument in another key as a `[K:…]` in its voices there. Wherever any part's key changes, or the parts open in different written keys, every voice writes its own part's key, so that each reads back spelled in its own key.
- The LilyPond reader reads `\tempo` with text, a metronome mark, or both, `\fermata` and its variants on notes and rests as timeline fermatas, and "rit.", "rall.", "accel.", and "a tempo" from `^"…"` and `^\markup` annotations, dropping other annotation text instead of raising.
- The LilyPond writer writes `\tempo` with text, a metronome mark, or both, `\fermata` on every voice event sounding where a fermata begins, and a tempo ramp's words at its start and its target `\tempo` at its end.
- The MEI reader reads `@fermata` and `<fermata>`, by `@startid` across measures or by `@tstamp`, into timeline fermatas, and the writer writes a `<fermata>` on every voice event sounding where a fermata begins.
- The MEI reader and writer keep tempo text in `<tempo>`, including text in `<rend>` and text with no `@mm`, which reads with `metronome_mark: false`.
- The MEI reader and writer read and write tempo ramps as `<tempo func="continuous">` with `@tstamp2` or `@endid`, toward the numbered `<tempo>` at the ramp's end, and "a tempo" points as `<tempo>` text.
- The MEI reader and writer keep the common- and cut-time symbols through `@meter.sym` and `<meterSig @sym>`.
- The MusicXML writer writes tempo text as `<words>` beside a `<metronome>` and a `<sound tempo>`, ramps as words with `<dashes>` to their target, "a tempo", `<fermata>` on every voice event sounding where a fermata begins, and the time `symbol` for common and cut time.
- The MusicXML reader reads `<fermata>` on notes, rests, and barlines into timeline fermatas, `<metronome>` and `<sound tempo>` anywhere in a bar, `<words>` as tempo text beside them or when they begin with a named tempo, ramps from ramp words and their `<dashes>`, "a tempo", and `<time symbol>`.
- The kern reader reads `;` fermatas on notes, rests, and chords into the timeline's fermatas, and the writer writes `;` on every voice event sounding where a fermata begins.
- The kern reader and writer keep common and cut time as `*met(c)` and `*met(c|)`, including a change of sign alone.
- The kern reader reads `!!!OMD` as the opening tempo's text and `*MM[Andante]` as tempo text, and the writer writes both; a flow with tempo ramps renders to kern at each bar's authored tempo.

### Changed

- The MusicXML reader trusts the written values of a measure whose rounded `<duration>`s overflow the bar while its `<type>`s, dots, and `<time-modification>`s fill it exactly in every voice, instead of refusing it as overfull. `<backup>` and `<forward>` land on the nearest written onset. Files written at divisions that cannot express their notes, such as music21's Beethoven op. 59 no. 2, now read; the corpus sweep reads 1,001 of 1,067 files.
- **Breaking.** `MusicXML::BarMap`, `MusicXML::VoiceTrack`, `MusicXML::TieFolding`, `MusicXML::VoicePlacer`, and `MusicXML::ConcertTransposition` move to `HeadMusic::Notation`, shared with MEI import, and `MusicXML::PitchReader`'s spelling helpers move to `Notation::PitchSpelling`. `MusicXML::XmlReading` and `MusicXML::ParsePreflight` remain. With the move, `VoicePlacer.new` requires `tuplet_reader:` (and takes `trim_edges:`), `ConcertTransposition.new` takes `errors:`, and the readings `BarMap` and `TieFolding` take must answer `errors` and `where`.
- `MusicXML.parse` raises `ParseError` on a document nesting elements deeper than 256.
- ABC reads a `P:` header, the playing order, and ignores it rather than raising. A repeat read from ABC plays as many times as the highest pass its endings name, rather than twice.
- ABC reads a `V:` voice id as the words before its `name=value` terms, in the header and the body alike, so `V:S clef=bass` continues voice `S` rather than starting a voice of that name, and `V:cantus firmus` keeps both words. A `K:` value skips its `clef=` and other `name=value` terms.
- ABC reads a tune's voices together in time order, rather than each line as it comes, so a tie, slur, or tuplet carries across a `V:` line into the voice's next line instead of ending there.
- **Breaking.** `ABC::BarWriter#bar` takes the key signature of its bar, and `ABC::PitchWriter#start_new_bar` takes an optional one, since a bar may open in a new key. `ABC::RenderPreflight.check!` no longer takes `transposed:`.
- **Breaking.** The ABC writer writes a flow of several voices, a meter or key change after the opening, and a transposed part that changes instrument, where it raised `RenderError`, and the ABC reader reads body `M:` and `K:` fields and inline `[M:…]` and `[K:…]`, where it raised `UnsupportedFeatureError`. The writer checks the dynamics of each voice with its part's where it writes them, rather than every part's and voice's together, so two voices may now hold different levels or hairpins at once.
- **Breaking.** `HeadMusic::Content::Placement` is `HeadMusic::Content::VoiceEvent`, a name for the time-filling notes, chords, and rests of a voice, apart from the point events such as dynamics still to come. The constant is gone, not aliased. `Voice#place` and `Voice#placements` keep their names, and the Flow JSON is unchanged. `HeadMusic::Notation::PlacementValidation` is `VoiceEventValidation` to match.
- **Breaking.** `VoiceEvent` is abstract, with two subclasses: `NoteEvent`, which holds one or more `Soundable`s and raises `ArgumentError` without one, and `RestEvent`, which is silent and cannot sing. `VoiceEvent.build` answers whichever the sounds call for, and `Voice#place` uses it. A note placed where a rest already stands now replaces the rest rather than turning it into a note, and keeps its beam flag; a rest placed on a note still leaves the note alone. Flow JSON that puts syllables on a rest raises `ArgumentError` naming its path.
- **Breaking.** Methods and arguments named for placements are named for voice events. `Voice#placements` is `Voice#voice_events`, `Voice#last_placement` is `#last_voice_event`, `Voice#rests` is `#rest_events` beside a new `#note_events` (which, unlike `#notes`, includes unpitched note events), `Position#within_placement?` is `#within_voice_event?`, and a style guideline's `rests` and `placements` follow. `Voice#place` keeps its name.
- **Breaking.** The serialization schema goes to 5: each voice's `"placements"` is now `"voice_events"`, and nothing else changes. `Flow.from_h` and `Project.from_h` refuse a v4 document and name the reader for it: `Flow.from_v4_h` and `Project.from_v4_h` read one by renaming the key, and are kept through 23.x so persisted documents can be read and saved again.
- **Breaking.** `Meter.get` returns a `Meter` it is given unchanged, rather than the registered meter with the same numerals, so a meter's symbol survives it.
- **Breaking.** `Tempo` compares by value, over its beat value, beats per minute, text, and metronome mark, with `eql?` and `hash` to match, where it had compared by identity. `Tempo.get` finds a named tempo in any case and keeps the spelling it was given as its text, writing `_` as a space, so `Tempo.get("allegro").text` is `"allegro"`, and answers it with `metronome_mark: false`; it memoizes on the exact identifier. A metronome mark such as `"q = 120"`, or a word it does not know, still has no text.
- **Breaking.** kern import times a `**dynam` level on a row where no `**kern` spine attacks by the Humdrum convention: such rows split the time between the timed rows around them evenly. A level written beside a held note, which had been placed at the next attack, now falls in the middle of the note.
- **Breaking.** Flow JSON refuses a voice event's articulations or ornaments that name one marking twice through an alias or another spelling, such as `["mordent", "lower_mordent"]` or `["accent", "Accent"]`, with the error a repeated key raises. It had read them as one.
- The kern, MEI, and LilyPond writers refuse an unpitched grace note with one message: `cannot render the unpitched grace note "snare drum" before 1:1:000: percussion rendering is not yet supported`.
- `MEI::RenderPlan::StaffEntry` is `MEI::StaffNumbering::Entry`, `MEI::RenderPlan::Item` is `MEI::WrittenItems::Item`, `MEI::LayerContainers::BEAM_LEVELS_BY_DUR` is `MEI::BeamContainers::LEVELS_BY_DUR`, and `MEI::MarkingEvents::ORNAMENTS` is `MEI::AttachedMarks::ORNAMENTS`.
- `rexml` is now a runtime dependency, in preparation for reading MusicXML and MEI.
- `Project#add_flow` adopts a player that a part already carries into the project's `players`, rather than leaving it out, and raises `ArgumentError` when that player belongs to another project.
- The MusicXML and LilyPond writers render a note that crosses a barline as tied notes, one per bar, instead of raising `RenderError`. A chord ties each of its pitches, and a rest splits into consecutive rests. Fourth-species flows now render.
- The LilyPond parser reads a tie across a bar check, such as `c'1~ | c'2`, as one placement instead of raising `ParseError`. A `\key` or `\time` written between the halves of such a tie takes effect at that barline; one in the middle of a bar still raises.
- The LilyPond writer renders a short final bar, such as one that balances a pickup, when every voice ends there together: it leaves the bar check off that bar, and a tacet voice rests only as long as the music, followed by spacers where a dynamic comes after the music in that bar. Voices that end at different points short of the final bar still raise `RenderError`.
- **Breaking.** The MusicXML writer's work title defaults to the title of the flow's `Work`, with the flow's name as the `<movement-title>`, so a flow that cites a work, such as one read from kern, writes it back. Pass `work_title:` to choose another; `work_title: nil` still falls back to the `Work`'s title.
- **Breaking.** `MusicXML::MarkingWriter` is `MusicXML::MarkingElements`, since the reader uses it too. The old constant is gone, not aliased.
- `MinimumNotes` with no minimum configured raises `KeyError`, as `MinimumMelodicIntervals` does, rather than `NameError`.
- **Breaking.** A contour guide grades a miss by its degree, at φ⁻² per degree, rather than every miss at φ⁻². An arch is read as a rise to its climax and a fall from it, each graded as a direction whose turn back may reach only half its net change, and a valley as the mirror. A small dip no longer turns an arch into a wave, so Fux's D F E D G F A G F E D and most published cantus firmi now pass `arch_contour_melody` and fail `wave_contour_melody`. A valley submitted to `arch_contour_melody` grades about 0.416 rather than 0.618. A wave needs three or more legs, the rises and falls of at least a minor third, and must not read as a single arch or valley. Ascending and descending are directions, read from the endpoints and the headway between them, with a degree for each condition failed: starting within a whole step of one extreme, ending within a whole step of the other, ending at least a minor third beyond where the melody began, and never turning back three quarters as far as that net change. So a melody that wanders between its endpoints matches if it makes headway, and one whose endpoint sits a step from its extreme now matches too. Static is unchanged. A miss names what is wrong, such as "Write the arch contour: reverse the rise and fall.", in place of "Write a melody with the arch contour."
- **Breaking.** A diatonic interval is named by its number through the seventeenth, as every locale translates it: `"major seventeenth"` rather than `"two octaves and a major third"`.
- **Breaking.** A plain LilyPond `\time 4/4` or `\time 2/2` reads as common or cut time, as LilyPond prints it, and `\numericTimeSignature` and `\defaultTimeSignature` switch the reading; the writer writes `\numericTimeSignature` before a 4/4 or 2/2 with no symbol, and `\defaultTimeSignature` when a symbol returns.
- **Breaking.** The LilyPond writer raises `RenderError` for a fractional tempo, which it used to drop with every other tempo.

### Removed

- **Breaking.** `Credits.from_h`, which nothing in the gem called. `Credits.new(level, array)` reads the same array of credit hashes, `nil` included.

### Fixed

- `Quality.get` reads `"doubly augmented"` and `"doubly diminished"` as written, so a doubly altered `DiatonicInterval` answers `doubly_augmented?`, `doubly_diminished?`, and `shorthand` (`"AA4"`) instead of raising `NoMethodError`. A quality's `to_s` is its name as written, and it equals either spelling.
- A diatonic interval altered past the next octave is named for it. An augmented fourteenth was named `" fourteenth"`, and an augmented compound seventh, or any doubly altered interval past the seventeenth, raised `NoMethodError`. An augmented compound octave counts one more octave and an augmented unison, so C3 to C♯6 is "three octaves and an augmented unison", not "three octaves and an augmented octave".
- The ABC parser names the line of a tie between notes of different pitches; it gave none.
- An MEI `@tuplet` run whose entries are not all scaled alike is left ungrouped, as when they are scaled by different ratios. A run of triplet and unscaled entries was grouped as a triplet when a triplet entry came first.
- The MEI, LilyPond, and ABC writers print an accidental on each chord member that shares a letter and octave with another under a different alteration, so F4 with F♯4 in C major shows its natural; LilyPond writes them as `<fis'! f'!>` so a later F in the bar prints correctly too.
- The LilyPond reader reads notes carrying a forced (`!`) or cautionary (`?`) accidental sign, such as `fis'!4`, rather than refusing them.
- Adding a tempo, meter, or key change to a flow, and growing its bars, no longer revisit every earlier change or bar, so a long flow with a change in each bar builds in linear time: 10,000 bars of tempo changes took 7.9 s and now take 0.12 s.
- `Key#relative` spells flat-side keys with flats: E♭ minor's relative is G♭ major, not F♯ major, and G♭ major's is E♭ minor, not D♯ minor.
- `Mode#relative_major` spells flat-side modes with flats, so E♭ Dorian's relative major is D♭ major, not C♯ major.
- MusicXML import folds tied chains in linear time; a long chain of tied notes had taken quadratic time.
- The MusicXML writer raises `RenderError` for a character XML forbids in a syllable, player or instrument name, rehearsal mark, Work title, or a `work_title:` or `arranger:` option, and for U+FFFE, U+FFFF, or text that is not valid UTF-8 or is non-ASCII text in another encoding, instead of writing ill-formed XML.
- The MusicXML writer renders a meter whose beat is longer than any note value, such as 6/1 or 12/1, leaving its notes unbeamed, instead of raising `NoMethodError`.
- `HeadMusic::Notation::ABC.parse` keeps the grace notes before a tied note, which it dropped when it folded the tie into one event.
- A transposed layout writes grace notes at written pitch, as it does their main notes, in MusicXML, LilyPond, and ABC. They had kept their concert pitch.
- **A `Content::Position` carried whole counts across a meter change in the origin bar's count unit.** A dotted half tied to a dotted half from `1:1` in 6/8, with 2/2 from bar 2, ended at `5:1:000`, its six leftover eighths spent as six halves, rather than at `2:2:960`. The carry now stops at the first bar with a different count unit and restates what is left there as ticks.
- The kern reader no longer raises "A null token … falls where no note is sounding" on a row holding only grace notes.
- MusicXML no longer raises beaming a compound-meter piece whose tuplets leave its beat without whole divisions.
- ABC tunes with slurs, and LilyPond files with slurs, phrasing slurs, or named slurs, import instead of raising `UnsupportedFeatureError` or, for `\(` and `\=1(`, `ParseError`.
- ABC tunes with a staccato dot, `T` or `M` shorthand, or `!…!` decorations, and LilyPond files with articulations or dynamics, import instead of raising. kern tokens with a `z` sforzando no longer raise `UnsupportedFeatureError`.
- The MusicXML writer writes a voice's dynamic that falls after its last note in a bar, as a `<direction>` after that note, instead of leaving it out.
- The ABC writer no longer writes a zero-length note (`C8-|C0`) for a note that crosses a barline and ends on a later one.
- `Position#+` adds a rhythmic value's subticks, so a length finer than a tick carries instead of being dropped: a dotted 256th from the downbeat ends at `1:1:022:120`, not `1:1:022`. `Position#advance(subticks:)` moves a position by subticks, and `BarSplitter.offset_in_bar` counts a position's subticks.
- `RhythmicValue` defines `eql?` and `hash` to match `==`, so `uniq` and `tally` count equal values together. `NotesSameLength` now finds the most common value in a line, rather than taking the first note's, and marks fewer notes in lines of mixed values.
- The MusicXML writer resets `<transpose>` to nothing where a transposed part changes back to an instrument in C, rather than leaving the old transposition in force; writes a clef change (`Staff#change_clef`) as a `<clef>` in the measure it falls in, numbered for its staff; and writes `<clef-octave-change>` for octave clefs such as the tenor's treble clef.
- `Flow#performance_order` plays the bar a final tied note reaches, rather than stopping at the bar it starts in.
- `Conductor#musical_to_clock` counts each bar in its own meter: 6:1 after a change from 4/4 to 3/4 at bar 5 is 9.5 s at ♩=120, not 10.0 s. `Conductor#clock_to_musical` no longer stops a thousand bars past the start.
- `Tempo.get("Andante")` answers an andante, ♩=78, instead of ♩=120, and `Tempo.get("Moderato")` a moderato instead of ♩=0: a named tempo is found in any case.
- MEI keeps an opening tempo's beat other than a quarter, in a `<tempo>` beside the `<scoreDef>`'s `@midi.bpm`.

### Security

- `rexml` must be at least 3.4.2, since 3.3.3 through 3.4.1 are open to a denial of service from XML with several XML declarations (CVE-2025-58767).

## [22.0.0] - 2026-09-24

Four counterpoint stories, [Require the Species Rhythm](https://github.com/roberthead/head_music/tree/main/user-stories/done/require-the-species-rhythm.md), [Embellish Fifth Species Suspensions](https://github.com/roberthead/head_music/tree/main/user-stories/done/embellish-fifth-species-suspensions.md), [Grade Every Fux Fifth-Species Figure](https://github.com/roberthead/head_music/tree/main/user-stories/done/grade-every-fux-fifth-species-figure.md), and [Fifth Species Guide Improvements](https://github.com/roberthead/head_music/tree/main/user-stories/done/fifth-species-guide-improvements.md). Every species guide now insists on the rhythm its species teaches, fifth species accepts the decorated suspensions Fux allows and requires the mixture that defines it, and every two-voice fifth-species figure in Gradus is graded and pinned. Fux's lines are graded as evidence, not as an oracle: where one of them outruns a rule that every other source keeps, the mark stands and is recorded as his liberty. Two grades move, both in the direction the pedagogy says they should, and the count guidelines now grade the solo and cantus-firmus lines they had passed on nothing; everything else is additive, including ties across bar lines in ABC.

Grading is also faster: the pinned corpus grades in about half the time, with no grade moving for it.

**This is a major release**, because two public classes are removed. A consumer that names neither and stores no schema-3 documents upgrades by upgrading.

**Migrating from 21.1.0**, in the order a consumer will hit them:

1. **`Style::Guidelines::MixedRhythmicValues` is gone.** A custom guide that names it raises `NameError` on load. `MixSpeciesTextures` replaces it in `FifthSpeciesMelody` and judges runs of one texture rather than counting distinct durations, so it is a successor rather than a rename.

2. **`Content::Flow.from_v3_h` is gone, as 21.0.0 announced.** A schema-3 document must be read with head_music 21.x and saved again before upgrading; `Flow.from_h` rejects one with an error saying so. Schema-4 documents are unaffected.

3. **Some grades move.** The rule changes under Added and Changed regrade existing lines: the fourth- and fifth-species guides most, and `Diatonic`, `StepOutOfUnison`, `AlwaysMove`, and the count guidelines in places. Stored fitness from 21.x is not comparable for the guides they touch.

4. **`Pitch#name` and `Spelling#name` return frozen strings.** Code that modifies the returned name in place raises `FrozenError`; `dup` it first.

### Added

- **`Style::Guidelines::MixSpeciesTextures`, strong and primary in `FifthSpeciesMelody` in place of `MixedRhythmicValues`.** Fifth species is the free mixture of the other four, and Salzer and Schachter allow "two, or at most, two-and-a-half measures of a single note value" (*Counterpoint in Composition*, pp. 101-102). Each bar from the voice's first to the one before its last is classified by the texture it shows: a note that fills the bar, halves, quarters and eighth pairs, or a ligature entered by tie. Every bar of a run of more than two bars in one texture is marked, configurable through `maximum_run:`. A bar that mixes textures is florid and an empty bar is left to the rest rules; either ends a run. It is strong although a proportion usually makes a guideline weak, because one texture running on decides whether a line is fifth species at all. All twelve Fux fifth-species counterpoints are adherent. Fux's fourth-species figure 73 falls from 0.929 to 0.827 on the `fifth_species` composite, its eight ligature bars marked in two runs on either side of an untied bar; his second- and third-species figures fall to 0.815 and 0.796, and every first-species counterpoint to between 0.59 and 0.63, and the species diagonal spec now asserts that every other species grades 0.85 or below there. In the pinned corpus, 175 rows move, all on `fifth_species_melody` and the `fifth_species` composite: every one-texture voice falls, including every cantus firmus, every first-species counterpoint, the solo and against-empty lines, and the cantus voices of the species fixtures; the triple-meter cantus counts too, since a dotted whole that fills its bar is the whole-note texture. Two three-bar solo lines rise on the melody guide and lose their one message on both guides, because two body bars cannot hold an over-long run, where the old rule marked any line with fewer than three durations. No other message or item count moves, and no harmony grade moves.

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

- **Guide grading allocates about a quarter as many objects.** Positions compare field by field rather than through arrays; pitch and spelling names, a pitch's natural, a letter name's pitch class, and a diatonic interval's quality are memoized; pitch classes and chromatic intervals looked up by number skip name parsing; rhythmic unit names are indexed once rather than normalized on every parse; and `AvoidCrossingVoices` finds the predominant orientation once per assessment. Grading the pinned corpus falls from about 18.5 to 9.4 seconds, and no grade moves. `Pitch#name` and `Spelling#name` now return frozen strings.

- **`Flow`, `Voice`, `Position`, and `Placement` inspect as one line.** Each shows its class and `to_s`, as in `#<HeadMusic::Content::Placement eighth F♯4 at 2:2:240>`. The default printed the whole composition, since every placement reaches its voice and every voice its flow: two melodic note pairs from a seven-note voice inspected to two megabytes, in irb, in failure messages, and in RSpec's generated example descriptions.

### Removed

- **`Content::Flow.from_v3_h` and `Content::Flow::V3HashDeserializer`,** as 21.0.0 announced. A schema-3 document is read with `Flow.from_v3_h` in head_music 21.x and saved again; `Flow.from_h` still rejects one with an error saying so.

- **`Style::Guidelines::MixedRhythmicValues`.** It asked only for three distinct durations and placed one mark when a line had fewer, which is why Fux's fourth-species line graded within 0.024 of his fifth-species line on the `fifth_species` composite. `MixSpeciesTextures` replaces it; no other guide used it.

### Fixed

- **ABC repeat and volta tagging for a note that outlasts its bar.** The parser counted completed bars from where the last note started, so a note longer than its bar, or one now tied across the line, shifted every following repeat flag by a bar. Bars are counted from where the last note ends.

- **`AvoidCrossingVoices` marks the bars that leave the predominant orientation.** It deduplicated the voices' orientations before counting them, so the orientation heard first always won, and a counterpoint that opened below the cantus firmus and then stayed above it had its in-order bars marked as the crossings. The most common orientation now wins, and a tie still goes to the one heard first. No row of the pinned corpus moves: every crossing voice in it opens in its predominant orientation.

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
