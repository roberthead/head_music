require "spec_helper"

# A sweep of real MusicXML corpora, run only when MUSICXML_CORPUS names one
# or more local folders, separated by colons. None of it is committed here.
# Each folder is labeled by its own name, and the manifest's paths start
# with that label:
#
# - corpus: music21's corpus (~/github.com/cuthbertLab/music21/music21/corpus)
# - music21_mxl: its .mxl files, each unzipped into the folder of its own
#   path less the extension, with META-INF removed
# - lilypondTestSuite: the LilyPond MusicXML test suite as music21 ships it
# - data: OpenSheetMusicDisplay's test/data
# - osmd_mxl: its .mxl files, unzipped the same way
#
# Every file parses with its music whole, or raises the error listed for it.
# What the files listed hold, by kind:
#
# - A short measure in the middle of the piece: an irregular bar, a pickup
#   into a new section or meter, endings that each balance an opening
#   pickup, or a meter change left unwritten. The bars cannot hold them.
# - An overfull measure: a meter left unwritten, parts in different meters,
#   or a deliberately wrong file. Rounded <duration>s that pass the bar
#   while the written values fill it, as in op. 59 no. 2 and
#   OSMD_function_test_all, read by their written values.
# - <duration>s that disagree with their <type>, a <backup> before its
#   measure, a voice overlapping itself, a note or rest past its bar, and
#   rests that fill no gap: inconsistent encodings, and the same drift.
# - No <divisions> in force, which the story makes a ParseError.
# - Compound meters, nested tuplets, microtones, chord tones of different
#   lengths, keys beyond seven accidentals, four dots, and triple sharps,
#   which the model cannot hold.
describe HeadMusic::Notation::MusicXML do
  corpora = ENV["MUSICXML_CORPUS"].to_s.split(File::PATH_SEPARATOR).reject(&:empty?).map { |folder| File.expand_path(folder) }
  parse_error = described_class::ParseError
  unsupported = described_class::UnsupportedFeatureError
  unreadable = {
    # corpus
    "corpus/demos/nested_tuplet_finale_test.xml" => [unsupported, /\ANested tuplets are not supported/],
    "corpus/demos/nested_tuplet_finale_test2.xml" => [unsupported, /\ANested tuplets are not supported/],
    "corpus/schubert/Lindenbaum.xml" => [unsupported, /\AChord tones of different lengths are not supported/],
    "corpus/schumann/opus41no1/movement4.xml" => [parse_error, /\AA <backup> reaches before the start of its measure/],
    "corpus/trecento/PMFC_13_09-Gloria Anglicana.xml" => [unsupported, /\AThe measure is shorter than its 9\/8 bar, and no measure after it completes it/],
    "corpus/trecento/PMFC_13_12-Gloria.xml" => [unsupported, /\AThe measure is longer than its 3\/4 bar/],
    "corpus/trecento/PMFC_13_18-Gloria Spiritus et Alme.xml" => [unsupported, /\AThe measure is shorter than its 9\/8 bar, and no measure after it completes it/],
    "corpus/trecento/PMFC_24_9-Gloria Ciconia 9.xml" => [unsupported, /\ANo rest fills the gap in voice 1/],
    # data
    "data/OSMD_Function_Test_Tablature_Alleffects.musicxml" => [unsupported, /\AThe measure is longer than its 4\/4 bar/],
    "data/OSMD_function_test_accidentals.musicxml" => [unsupported, /\AThe pitch G altered by 3 in octave 4 has no spelling/],
    "data/test_clef_change_on_invisible_note_norma_fantasy_1605.musicxml" => [parse_error, /\AA <duration> of 353 disagrees with its 2:1 half at 480\/1 divisions/],
    "data/test_divisions_after_first_note_JingleBellRock_extract.musicxml" => [parse_error, /\AA <duration> has no <divisions> in force/],
    "data/test_quarter_accidentals.musicxml" => [unsupported, /\AMicrotonal <alter> 0\.5 is not supported/],
    "data/test_tie_missing_invalid_rest_duration_1530.musicxml" => [unsupported, /\AThe measure is longer than its 2\/4 bar/],
    "data/test_ties_missing_1097.musicxml" => [unsupported, /\AChord tones of different lengths are not supported/],
    "data/test_time_signature_missing_deliberately_gnossienne.musicxml" => [unsupported, /\AThe measure is longer than its 4\/4 bar/],
    "data/test_tuplet_nested_issue_1583.musicxml" => [parse_error, /\AA <duration> of 24 disagrees with its triplet quarter at 24\/1 divisions/],
    # lilypondTestSuite
    "lilypondTestSuite/01b-Pitches-Intervals.xml" => [unsupported, /\AThe measure is shorter than its 4\/4 bar, and no measure after it completes it/],
    "lilypondTestSuite/01d-Pitches-Microtones.xml" => [unsupported, /\AMicrotonal <alter> -1\.5 is not supported/],
    "lilypondTestSuite/01f-Pitches-EditorialMicrotoneAccidentals.xml" => [unsupported, /\AMicrotonal <alter> -0\.5 is not supported/],
    "lilypondTestSuite/03d-Rhythm-DottedDurations-Factors.xml" => [unsupported, /\AA note with 4 dots is not supported/],
    "lilypondTestSuite/11b-TimeSignatures-NoTime.xml" => [parse_error, /\AA <backup> reaches before the start of its measure/],
    "lilypondTestSuite/11c-TimeSignatures-CompoundSimple.xml" => [unsupported, /\ACompound meters such as 3\+2\/8 are not supported/],
    "lilypondTestSuite/11d-TimeSignatures-CompoundMultiple.xml" => [unsupported, /\ACompound meters such as 3\/8 are not supported/],
    "lilypondTestSuite/11e-TimeSignatures-CompoundMixed.xml" => [unsupported, /\ACompound meters such as 3\+2\/8 are not supported/],
    "lilypondTestSuite/11f-TimeSignatures-SymbolMeaning.xml" => [unsupported, /\ACompound meters such as 3\+2\/8 are not supported/],
    "lilypondTestSuite/13aa-KeySignatures-Extreme.xml" => [unsupported, /\AA key of -11 fifths is not supported/],
    "lilypondTestSuite/23d-Tuplets-Nested.xml" => [unsupported, /\ANested tuplets are not supported/],
    "lilypondTestSuite/32b-Articulations-Texts.xml" => [parse_error, /\AA <duration> of 384 disagrees with its eighth at 96\/1 divisions/],
    "lilypondTestSuite/32d-Arpeggio.xml" => [unsupported, /\AThe measure is longer than its 4\/4 bar/],
    "lilypondTestSuite/33e-Spanners-OctaveShifts-InvalidSize.xml" => [parse_error, /\AA <duration> of 4 disagrees with its quarter at 1\/1 divisions/],
    "lilypondTestSuite/41g-PartNoId.xml" => [parse_error, /\AA <duration> has no <divisions> in force/],
    "lilypondTestSuite/41h-TooManyParts.xml" => [parse_error, /\AA <duration> has no <divisions> in force/],
    "lilypondTestSuite/46f-IncompleteMeasures.xml" => [unsupported, /\AThe measure is shorter than its 4\/4 bar, and no measure after it completes it/],
    "lilypondTestSuite/51b-Header-Quotes.xml" => [parse_error, /\AA <duration> has no <divisions> in force/],
    "lilypondTestSuite/51c-MultipleRights.xml" => [parse_error, /\AA <duration> has no <divisions> in force/],
    "lilypondTestSuite/51d-EmptyTitle.xml" => [parse_error, /\AA <duration> has no <divisions> in force/],
    "lilypondTestSuite/74a-FiguredBass.xml" => [parse_error, /\AA <duration> of 8 disagrees with its dotted eighth at 8\/1 divisions/],
    # music21_mxl
    "music21_mxl/bach/bwv119.9/bwv119.9.xml" => [unsupported, /\AThe measure is longer than its 4\/4 bar/],
    "music21_mxl/bach/bwv171.6/bwv171.6.xml" => [unsupported, /\AThe measure is shorter than its 4\/4 bar, and no measure after it completes it/],
    "music21_mxl/bach/bwv261/bwv261.xml" => [unsupported, /\AThe measure is shorter than its 4\/4 bar, and no measure after it completes it/],
    "music21_mxl/bach/bwv276/bwv276.xml" => [unsupported, /\AThe measure is shorter than its 4\/4 bar, and no measure after it completes it/],
    "music21_mxl/bach/bwv304/bwv304.xml" => [unsupported, /\AThe measure is shorter than its 3\/4 bar, and no measure after it completes it/],
    "music21_mxl/bach/bwv324/bwv324.xml" => [unsupported, /\AThe measure is longer than its 4\/4 bar/],
    "music21_mxl/bach/bwv372/bwv372.xml" => [unsupported, /\AThe measure is shorter than its 4\/4 bar, and no measure after it completes it/],
    "music21_mxl/bach/bwv41.6/bwv41.6.xml" => [unsupported, /\AThe measure is shorter than its 4\/4 bar, and no measure after it completes it/],
    "music21_mxl/beethoven/opus132/opus132.xml" => [unsupported, /\AThe measure is shorter than its 4\/4 bar, and no measure after it completes it/],
    "music21_mxl/beethoven/opus133/opus133.xml" => [parse_error, /\AA <duration> of 228 disagrees with its triplet eighth at 1024\/1 divisions/],
    "music21_mxl/beethoven/opus18no1/movement1/movement1.xml" => [unsupported, /\AThe measure is longer than its 3\/4 bar/],
    "music21_mxl/beethoven/opus18no1/movement2/movement2.xml" => [unsupported, /\ANo note value spans a <duration> of 59/],
    "music21_mxl/beethoven/opus18no1/movement4/movement4.xml" => [unsupported, /\AThe measure is longer than its 2\/4 bar/],
    "music21_mxl/beethoven/opus18no3/opus18no3.xml" => [unsupported, /\AThe measure is shorter than its 3\/4 bar, and no measure after it completes it/],
    "music21_mxl/beethoven/opus18no4/opus18no4.xml" => [unsupported, /\AThe measure is shorter than its 4\/4 bar, and no measure after it completes it/],
    "music21_mxl/beethoven/opus18no5/opus18no5.xml" => [unsupported, /\AThe measure is shorter than its 3\/4 bar, and no measure after it completes it/],
    "music21_mxl/beethoven/opus59no1/movement4/movement4.xml" => [parse_error, /\AA <backup> reaches before the start of its measure/],
    "music21_mxl/beethoven/opus59no3/movement1/movement1.xml" => [unsupported, /\AThe measure is shorter than its 3\/4 bar, and no measure after it completes it/],
    "music21_mxl/beethoven/opus59no3/movement2/movement2.xml" => [unsupported, /\AThe measure is longer than its 6\/8 bar/],
    "music21_mxl/beethoven/opus59no3/movement4/movement4.xml" => [unsupported, /\AThe measure is shorter than its 3\/4 bar, and no measure after it completes it/],
    "music21_mxl/beethoven/opus74/opus74.xml" => [unsupported, /\AThe measure is shorter than its 3\/4 bar, and no measure after it completes it/],
    "music21_mxl/demos/incorrect_time_signature_pv/320.xml" => [unsupported, /\AThe measure is longer than its 4\/4 bar/],
    "music21_mxl/haydn/opus1no1/movement1/movement1.xml" => [unsupported, /\AThe measure is shorter than its 6\/8 bar, and no measure after it completes it/],
    "music21_mxl/haydn/opus1no1/movement2/movement2.xml" => [unsupported, /\AThe measure is longer than its 3\/4 bar/],
    "music21_mxl/haydn/opus1no1/movement4/movement4.xml" => [unsupported, /\AThe measure is shorter than its 3\/4 bar, and no measure after it completes it/],
    "music21_mxl/haydn/opus74no1/movement3/movement3.xml" => [unsupported, /\AThe measure is longer than its 3\/4 bar/],
    "music21_mxl/schumann/opus41no1/movement1/movement1.xml" => [parse_error, /\AVoice 1 overlaps itself/],
    "music21_mxl/weber/concertino_clarinet/concertino_clarinet.xml" => [unsupported, /\AThe measure is longer than its 6\/8 bar/]
  }

  before { skip "set MUSICXML_CORPUS to local folders of MusicXML files" if corpora.empty? }

  files = corpora.flat_map do |folder|
    label = File.basename(folder)
    Dir[File.join(folder, "**", "*.{xml,musicxml}")].sort.map { |path| ["#{label}/#{path.delete_prefix("#{folder}/")}", path] }
  end

  files.each do |name, path|
    if unreadable.key?(name)
      error_class, message = unreadable.fetch(name)
      it "refuses #{name}" do
        expect { described_class.parse(File.binread(path)) }.to raise_error { |error| expect([error.class, error.message]).to match [error_class, message] }
      end
    else
      it "reads #{name} with its music whole" do
        expect_music_whole(described_class.parse(File.binread(path)))
      end
    end
  end

  it "lists only files the corpora hold" do
    labels = corpora.map { |folder| File.basename(folder) }
    listed = unreadable.keys.select { |name| labels.include?(name.split("/").first) }
    expect(listed - files.map(&:first)).to eq []
  end
end
