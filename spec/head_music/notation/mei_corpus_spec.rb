require "spec_helper"

# A sweep of real MEI corpora, run only when MEI_CORPUS names one or more
# local folders, separated by colons. None of it is committed here. Each
# folder is labeled by its own name, and the manifest's paths and globs
# start with that label:
#
# - MEI_5.1, MEI_5.0, MEI_4.0: those folders of music-encoding's
#   sample-encodings (~/github.com/music-encoding/sample-encodings), which
#   hold the same 167 files in each version and refuse alike;
# - test: music21's MEI test files (~/github.com/cuthbertLab/music21/music21/mei/test).
#
# Every file parses with each flow's music whole, or raises the error listed
# for it. No error outside HeadMusic::Notation::ParseError escapes either
# way. What the files listed hold, by kind:
#
# - Header examples: a <perfMedium> or <watermark> fragment as the root, or
#   a document with a header and no <score>.
# - An overfull measure as encoded: two voices written one after the other
#   in one layer, a beat too many, a hidden spacer layer longer than its bar,
#   or @tuplet runs whose <tupletSpan> is missing, names no ratio, or names
#   the wrong one. Beethoven's op. 18 no. 1 has a span whose @endid lands
#   four bars on, inside the next tuplet, which reads as nested.
# - A short measure in the middle of the piece, such as the end of a repeat
#   that an upbeat elsewhere completes, which the bars cannot hold.
# - A <note> or <chord> with no @dur and no @dur.default, a <chord> whose
#   notes differ in length, and a <note> with no @pname or @oct: nothing
#   the model could hold.
# - A later <scoreDef> that restates only some staves, refused as one that
#   adds or removes staves.
# - Empty <score>s, which make no flow; opera.mei's scores that do hold
#   music then stop on a note with no @oct.
# - music21's test_file.mei, whose <layer n=""> no MEI version allows.
describe HeadMusic::Notation::MEI do
  corpora = ENV["MEI_CORPUS"].to_s.split(File::PATH_SEPARATOR).reject(&:empty?).map { |folder| File.expand_path(folder) }
  parse_error = described_class::ParseError
  unsupported = described_class::UnsupportedFeatureError
  shorter = ->(meter) { [unsupported, /\AThe measure is shorter than its #{Regexp.escape(meter)} bar, and no measure after it completes it/] }
  longer = ->(meter) { [unsupported, /\AThe measure is longer than its #{Regexp.escape(meter)} bar/] }
  no_dur = ->(name) { [parse_error, /\AA <#{name}> has no @dur, and no @dur\.default is in force/] }
  restated = [unsupported, /\AA <scoreDef> that adds or removes staves is not supported/]
  no_score = [parse_error, /\AMEI input has no <score> or <part> in its <body>/]
  unreadable = {
    "MEI_*/Header/PerfMedium/**/*.mei" => [parse_error, /\AMEI input has a <perfMedium> root, not <mei>, <meiCorpus>, or <music>/],
    "MEI_*/Header/Watermark/*.mei" => [parse_error, /\AMEI input has a <watermark> root, not <mei>, <meiCorpus>, or <music>/],
    "MEI_*/Header/{Authority_data,FRBR,Minimal_header}/*.mei" => no_score,
    "MEI_*/Music/Complete_examples/Altenburg_Concerto_C-major.mei" => longer.call("2/4"),
    "MEI_*/Music/Complete_examples/Altenburg_Macht_auf_die_Tor.mei" => longer.call("6/4"),
    "MEI_*/Music/Complete_examples/Beethoven_StringQuartet_Op18_No1.mei" => [unsupported, /\ANested tuplets are not supported \(measure 96, staff 1/],
    "MEI_*/Music/Complete_examples/Brahms_StringQuartet_Op51_No1.mei" => longer.call("3/4"),
    "MEI_*/Music/Complete_examples/Chopin_Mazurka_Op6_No1.mei" => [parse_error, /\AA <note> has no @pname/],
    "MEI_*/Music/Complete_examples/Gluck_CheFaroSenzaEuridice.mei" => [parse_error, /\AA <note> has no @oct/],
    "MEI_*/Music/Complete_examples/Grieg_Butterfly_Op43_No1.mei" => longer.call("4/4"),
    "MEI_*/Music/Complete_examples/Haydn_StringQuartet_Op1_No1.mei" => shorter.call("6/8"),
    "MEI_*/Music/Complete_examples/Hummel_Concerto_for_trumpet_E-major.mei" => shorter.call("2/4"),
    "MEI_*/Music/Complete_examples/Hummel_Preludes_Op67_No11.mei" => longer.call("9/4"),
    "MEI_*/Music/Complete_examples/Ives_TheCage.mei" => no_dur.call("chord"),
    "MEI_*/Music/Complete_examples/McFerrin_Don't_worry.mei" => longer.call("4/4"),
    "MEI_*/Music/Complete_examples/Pachelbel_Canon_in_D.mei" => longer.call("4/4"),
    "MEI_*/Music/Complete_examples/Parker-Gillespie_ShawNuff.mei" => longer.call("4/4"),
    "MEI_*/Music/Complete_examples/Ravel_Le_tombeau.mei" => shorter.call("2/4"),
    "MEI_*/Music/Complete_examples/Rimsky-Korsakov_StringQuartet_B-LA-F.mei" => no_dur.call("note"),
    "MEI_*/Music/Complete_examples/Scarlatti_Sonata_in_C-major.mei" => shorter.call("2/2"),
    "MEI_*/Music/Complete_examples/Schubert_Erlkoenig.mei" => no_dur.call("note"),
    "MEI_*/Music/Complete_examples/Schubert_Lindenbaum.mei" => longer.call("3/4"),
    "MEI_*/Music/Complete_examples/Schumann_StringQuartet_Op41_No1.mei" => no_dur.call("note"),
    "MEI_*/Music/Complete_examples/Vivaldi_ViolinConcert_Op8_No2.mei" => longer.call("3/8"),
    "MEI_*/Music/Editorial_markup/Weber_op73/Editorial_markup.mei" => restated,
    "MEI_*/Music/Layout_information/Layout_information.mei" => longer.call("6/8"),
    "MEI_*/Music/Lyrics/lyrics.mei" => no_dur.call("note"),
    "MEI_*/Music/Lyrics/multiple_verses.mei" => longer.call("3/4"),
    "MEI_*/Music/Music_structure/{group_element,opera}.mei" => [parse_error, /\AMEI input contains no music/],
    "MEI_*/Music/Music_structure/multiple_sections{I,II}.mei" => longer.call("2/4"),
    "MEI_*/Music/Music_structure/mdivs_Tschaikovsky/Tschaikovsky_Symphony_No5_Op64_mulitple_mdivs.mei" => longer.call("4/4"),
    "MEI_*/Musical-features/snippets/Figured_Bass.mei" => no_dur.call("note"),
    "MEI_*/Musical-features/snippets/attribute_copyof.mei" => longer.call("3/4"),
    "MEI_*/Musical-features/snippets/{beamSpans,slur_element}.mei" => restated,
    "MEI_*/Musical-features/snippets/grace_Notes.mei" => longer.call("2/4"),
    "MEI_*/Musical-features/snippets/special_features.mei" => longer.call("3/4"),
    "MEI_*/Musical-features/snippets/short_examples/ambig.mei" => longer.call("5/8"),
    "MEI_*/Musical-features/snippets/short_examples/bidur.mei" => no_dur.call("chord"),
    "MEI_*/Musical-features/snippets/short_examples/{finger2,fractup}.mei" => [unsupported, /\AThe measure is longer than its [34]\/4 bar/],
    "MEI_*/Musical-features/snippets/short_examples/secondary.mei" => [parse_error, /\AA <note> has no @oct/],
    "MEI_*/docStarts/Doc_starts_with_meiCorpus.mei" => no_score,
    "MEI_*/docStarts/Doc_starts_with_meiHead.mei" => [parse_error, /\AMEI input has a <meiHead> root, not <mei>, <meiCorpus>, or <music>/],
    "MEI_*/docStarts/Doc_starts_with_music.mei" => no_dur.call("note"),
    "test/test_file.mei" => [parse_error, /\AUnreadable @n "" \(measure 6, staff 2, <layer>\)/]
  }

  matching = ->(pattern, name) { File.fnmatch?(pattern, name, File::FNM_PATHNAME | File::FNM_EXTGLOB) }

  before { skip "set MEI_CORPUS to local folders of MEI files" if corpora.empty? }

  files = corpora.flat_map do |folder|
    label = File.basename(folder)
    Dir[File.join(folder, "**", "*.mei")].sort.map { |path| ["#{label}/#{path.delete_prefix("#{folder}/")}", path] }
  end

  files.each do |name, path|
    patterns = unreadable.keys.select { |pattern| matching.call(pattern, name) }
    if patterns.any?
      error_class, message = unreadable.fetch(patterns.first)
      it "refuses #{name}" do
        expect(patterns.length).to eq 1
        expect { described_class.parse_book(File.binread(path)) }.to raise_error { |error| expect([error.class, error.message]).to match [error_class, message] }
      end
    else
      it "reads #{name} with each flow's music whole" do
        flows = described_class.parse_book(File.binread(path))
        expect(flows).not_to be_empty
        flows.each { |flow| expect_mei_music_whole(flow) }
      end
    end
  end

  it "lists only paths and globs that match a file in the corpora" do
    labels = corpora.map { |folder| File.basename(folder) }
    listed = unreadable.keys.select { |pattern| labels.any? { |label| File.fnmatch?(pattern.split("/").first, label) } }
    expect(listed.reject { |pattern| files.any? { |name, _| matching.call(pattern, name) } }).to eq []
  end
end
