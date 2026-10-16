require "spec_helper"

describe HeadMusic::Notation::MEI do
  def parse(*items, **options)
    described_class.parse(mei_document(*items, **options))
  end

  def events(*items, voice: 0, **options)
    parse(*items, **options).voices[voice].voice_events.map(&:to_s)
  end

  describe "pitches" do
    it "reads @pname and @oct" do
      expect(events(mei_staff(1, mei_note("C4", "2") + mei_note("G5", "2")))).to eq ["half C4 at 1:1:000", "half G5 at 1:3:000"]
    end

    it "lets @pname.ges and @oct.ges win" do
      expect(events(mei_staff(1, mei_note("C4", "1", pname_ges: "d", oct_ges: "3")))).to eq ["whole D3 at 1:1:000"]
    end

    it "raises on a note with no @pname" do
      expect { parse(mei_staff(1, %(<note oct="4" dur="1"/>))) }.to raise_error(described_class::ParseError, /no @pname \(measure 1, staff 1, <note>\)/)
    end
  end

  describe "accidentals" do
    it "sounds @accid.ges over @accid" do
      expect(events(mei_staff(1, mei_note("C4", "1", accid: "s", accid_ges: "f")))).to eq ["whole C♭4 at 1:1:000"]
    end

    it "reads a child <accid> as either" do
      notes = %(<note pname="f" oct="4" dur="2"><accid accid="s"/></note><note pname="b" oct="4" dur="2"><accid accid.ges="f"/></note>)
      expect(events(mei_staff(1, notes))).to eq ["half F♯4 at 1:1:000", "half B♭4 at 1:3:000"]
    end

    it "takes what the key implies where none is written" do
      expect(events(mei_staff(1, mei_note("F4", "1", accid: nil)), score_def: mei_score_def(keysig: "1s"))).to eq ["whole F♯4 at 1:1:000"]
    end

    it "carries a shown accidental to later notes at its letter and octave in the bar, and not past the barline" do
      bar = mei_note("F4", "4", accid: "s") + mei_note("F4", "4", accid: nil) + mei_note("F5", "2", accid: nil)
      expect(events(mei_staff(1, bar), mei_staff(1, mei_note("F4", "1", accid: nil))).map { |event| event.split[1] })
        .to eq %w[F♯4 F♯4 F5 F4]
    end

    it "carries an accidental across the staff's layers in onset order" do
      layers = [[1, mei_note("C5", "2", accid: nil) + mei_note("F4", "2", accid: nil)], [2, mei_note("F4", "4", accid: "s") + mei_rest("2", dots: "1")]]
      expect(events(mei_staff(1, *layers)).last).to eq "half F♯4 at 1:3:000"
    end

    describe "a <keySig> in a layer" do
      let(:key_bar) { mei_staff(1, %(<keySig sig="2s"/>) + mei_note("F4", "2", accid: nil) + mei_note("C4", "2", accid: nil)) }
      let(:f_bar) { mei_staff(1, mei_note("F4", "1", accid: nil)) }

      it "changes the staff's key from its bar where it opens the layer" do
        expect(events(f_bar, key_bar, f_bar)).to eq ["whole F4 at 1:1:000", "half F♯4 at 2:1:000", "half C♯4 at 2:3:000", "whole F♯4 at 3:1:000"]
      end

      it "changes the score's key there where the staves state it, as a <staffDef> does" do
        group = "<staffGrp>#{mei_staff_def(1, attributes: %( keysig="0" meter.count="4" meter.unit="4"))}</staffGrp>"
        flow = parse(f_bar, key_bar, score_def: mei_score_def(keysig: nil, meter: nil, staff_grp: group))
        expect(flow.key_signature_changes.transform_values { |event| event.key_signature.name }).to eq(2 => "D major")
      end

      it "refuses one after the layer's first event, naming the measure" do
        layer = mei_note("C4", "2") + %(<keySig sig="2s"/>) + mei_note("F4", "2", accid: nil)
        expect { parse(f_bar, mei_staff(1, layer)) }.to raise_error(described_class::UnsupportedFeatureError, /<keySig> after the first event of a <layer> is not supported \(measure 2, staff 1, <keySig>\)/)
      end
    end

    it "refuses a microtonal accidental" do
      expect { parse(mei_staff(1, mei_note("C4", "1", accid: "1qs"))) }.to raise_error(described_class::UnsupportedFeatureError, /microtonal/)
    end
  end

  describe "durations" do
    it "reads @dur and @dots" do
      expect(events(mei_staff(1, mei_note("C4", "2", dots: "1") + mei_note("D4", "4")))).to eq ["dotted half C4 at 1:1:000", "quarter D4 at 1:4:000"]
    end

    it "falls back to the chord's @dur, then to @dur.default" do
      chord = %(<chord dur="2"><note pname="c" oct="4"/><note pname="e" oct="4"/></chord>)
      score_def = mei_score_def(extra: %( dur.default="2"))
      expect(events(mei_staff(1, chord + %(<note pname="g" oct="4"/>)), score_def: score_def))
        .to eq ["half C4 E4 at 1:1:000", "half G4 at 1:3:000"]
    end

    describe "@dur.default" do
      let(:bare) { %(<note pname="g" oct="4"/>) }

      it "takes a <layerDef>'s for its layer over its staff's" do
        staff_def = mei_staff_def(1, attributes: %( dur.default="1"), inside: %(<layerDef n="2" dur.default="2"/>))
        flow = parse(mei_staff(1, [1, bare], [2, bare * 2]), score_def: mei_score_def(staff_grp: "<staffGrp>#{staff_def}</staffGrp>"))
        expect(flow.voices.map { |voice| voice.voice_events.map(&:to_s) }).to eq [["whole G4 at 1:1:000"], ["half G4 at 1:1:000", "half G4 at 1:3:000"]]
      end

      it "takes a later <scoreDef>'s from its measure on, over the staff's before it" do
        score_def = mei_score_def(staff_grp: "<staffGrp>#{mei_staff_def(1, attributes: %( dur.default="1"))}</staffGrp>")
        expect(events(mei_staff(1, bare), %(<scoreDef dur.default="2"/>), mei_staff(1, bare * 2), score_def: score_def))
          .to eq ["whole G4 at 1:1:000", "half G4 at 2:1:000", "half G4 at 2:3:000"]
      end

      it "takes a later <layerDef>'s from its measure on" do
        later = %(<staffDef n="1"><layerDef n="1" dur.default="2"/></staffDef>)
        expect(events(mei_staff(1, bare), later, mei_staff(1, bare * 2), score_def: mei_score_def(extra: %( dur.default="1"))))
          .to eq ["whole G4 at 1:1:000", "half G4 at 2:1:000", "half G4 at 2:3:000"]
      end
    end

    it "raises on a note with no @dur and none in force" do
      expect { parse(mei_staff(1, %(<note pname="c" oct="4"/>))) }.to raise_error(described_class::ParseError, /no @dur/)
    end

    it "refuses a @dur the model has no value for" do
      expect { parse(mei_staff(1, mei_note("C4", "1024"))) }.to raise_error(described_class::UnsupportedFeatureError, /no note value/)
    end
  end

  describe "rests" do
    it "reads <rest> and <space> as rests of their length" do
      expect(events(mei_staff(1, mei_rest("2") + %(<space dur="4"/>) + mei_note("C4"))))
        .to eq ["half rest at 1:1:000", "quarter rest at 1:3:000", "quarter C4 at 1:4:000"]
    end

    describe "a <space> with no @dur" do
      def voices(*items, score_def: mei_score_def(clefs: [%w[G 2], %w[F 4]]))
        parse(*items, score_def: score_def).voices.map { |voice| voice.voice_events.map(&:to_s) }
      end

      it "takes the time its layer leaves of the longest other layer in the measure" do
        expect(voices(mei_staff(1, mei_note("E5", "1")) + mei_staff(2, %(<space/>) + mei_note("C3", "2"))).last)
          .to eq ["half rest at 1:1:000", "half C3 at 1:3:000"]
      end

      it "shares that time equally among several in the layer" do
        expect(voices(mei_staff(1, mei_note("E5", "1")) + mei_staff(2, %(<space/>) + mei_note("C3") + %(<space/>))).last)
          .to eq ["dotted quarter rest at 1:1:000", "quarter C3 at 1:2:480", "dotted quarter rest at 1:3:480"]
      end

      it "takes a whole-bar rest beside it as the bar's length" do
        expect(voices(mei_staff(1, mei_note("E5", "1")), mei_staff(1, "<mRest/>") + mei_staff(2, mei_note("C3") + %(<space/>))).last)
          .to eq ["quarter C3 at 2:1:000", "dotted half rest at 2:2:000"]
      end

      it "reads a <rest> with no @dur as such a space, filling its bar alone in its layer, as Schumann's Op. 41 writes one" do
        expect(voices(mei_staff(1, mei_note("E5", "1")) + mei_staff(2, "<rest/>"), mei_staff(1, "<rest/>")).map(&:first))
          .to eq ["whole E5 at 1:1:000", "whole rest at 1:1:000"]
      end

      it "fills the meter's length in a measure of nothing but such spaces" do
        expect(voices(mei_staff(1, mei_note("E5", "1")), mei_staff(1, %(<space/>)) + mei_staff(2, %(<space/><space/>)), mei_staff(1, mei_note("D5", "1"))).first)
          .to eq ["whole E5 at 1:1:000", "whole rest at 2:1:000", "whole D5 at 3:1:000"]
      end

      it "takes the meter's length where every layer holds such a space, as Ravel's Le tombeau writes its bar 71" do
        layer = %(<space/>) * 2 + mei_note("C4", "8") * 2
        expect(voices(mei_staff(1, layer) + mei_staff(2, mei_note("C3", "8") + %(<space/>)), score_def: mei_score_def(meter: [2, 4], clefs: [%w[G 2], %w[F 4]])))
          .to eq [["eighth rest at 1:1:000", "eighth rest at 1:1:480", "eighth C4 at 1:2:000", "eighth C4 at 1:2:480"], ["eighth C3 at 1:1:000", "dotted quarter rest at 1:1:480"]]
      end
    end

    it "reads a @cue note as a rest" do
      expect(events(mei_staff(1, mei_note("C4", "2", cue: "true") + mei_note("D4", "2")))).to eq ["half rest at 1:1:000", "half D4 at 1:3:000"]
    end

    it "fills a bar of <mRest> between notes" do
      expect(events(mei_staff(1, mei_note("C4", "1")), mei_staff(1, "<mRest/>"), mei_staff(1, mei_note("D4", "1"))))
        .to eq ["whole C4 at 1:1:000", "whole rest at 2:1:000", "whole D4 at 3:1:000"]
    end
  end

  describe "chords" do
    it "reads a <chord> as one event of several pitches" do
      expect(events(mei_staff(1, %(<chord dur="1"><note pname="c" oct="4"/><note pname="g" oct="4"/></chord>)))).to eq ["whole C4 G4 at 1:1:000"]
    end

    it "reads a <chord> with no @dur at the @dur and @dots its notes share, as Schubert's Erlkönig writes one, and raises where they differ" do
      shared = %(<chord><note pname="c" oct="4" dur="2" dots="1"/><note pname="e" oct="4" dur="2" dots="1"/></chord>)
      differing = %(<chord><note pname="c" oct="4" dur="2"/><note pname="e" oct="4" dur="4"/></chord>)
      expect(events(mei_staff(1, shared + mei_note("G4")))).to eq ["dotted half C4 E4 at 1:1:000", "quarter G4 at 1:4:000"]
      expect { parse(mei_staff(1, differing + mei_note("G4", "2"))) }.to raise_error(described_class::ParseError, /<chord> has no @dur/)
    end

    it "raises on a chord of no notes" do
      expect { parse(mei_staff(1, %(<chord dur="1"/>))) }.to raise_error(described_class::ParseError, /<chord> has no <note>/)
    end
  end

  describe "grace notes" do
    def graces(*items)
      parse(*items).voices.first.voice_events.flat_map { |event| event.grace_notes.map(&:to_s) }
    end

    it "reads @grace, slashed where it is unacc, taking time from the note before" do
      expect(graces(mei_staff(1, mei_note("D4", "8", grace: "unacc") + mei_note("E4", "16", grace: "acc") + mei_note("C4", "1"))))
        .to eq ["slashed grace eighth D4", "grace sixteenth E4"]
    end

    it "reads a <graceGrp>, an eighth where no @dur is given" do
      expect(graces(mei_staff(1, %(<graceGrp grace="unacc"><note pname="d" oct="4"/></graceGrp>) + mei_note("C4", "1"))))
        .to eq ["slashed grace eighth D4"]
    end
  end

  describe "containers" do
    it "reads through <beam>, and a <bTrem>'s note" do
      expect(events(mei_staff(1, %(<beam>#{mei_note("C4", "8")}#{mei_note("D4", "8")}</beam><bTrem>#{mei_note("E4", "2", dots: "1")}</bTrem>))))
        .to eq ["eighth C4 at 1:1:000", "eighth D4 at 1:1:480", "dotted half E4 at 1:2:000"]
    end

    it "reads an <fTrem>'s members in sequence at their own @dur" do
      expect(events(mei_staff(1, %(<fTrem>#{mei_note("C4", "2")}#{mei_note("E4", "2")}</fTrem>)))).to eq ["half C4 at 1:1:000", "half E4 at 1:3:000"]
    end

    %w[mRpt mRpt2 beatRpt halfmRpt multiRpt].each do |name|
      it "refuses a <#{name}>, naming its measure" do
        expect { parse(mei_staff(1, mei_note("C4", "1")), mei_staff(1, "<#{name}/>")) }
          .to raise_error(described_class::UnsupportedFeatureError, /<#{name}> is not supported \(measure 2/)
      end
    end

    it "skips a clef and a barline inside a layer" do
      expect(events(mei_staff(1, mei_note("C4", "2") + %(<clef shape="F" line="4"/><barLine/>) + mei_note("D4", "2"))))
        .to eq ["half C4 at 1:1:000", "half D4 at 1:3:000"]
    end
  end

  describe "editorial markup in a layer" do
    it "reads the lemma and the correction, and skips a deletion" do
      app = %(<app><lem>#{mei_note("C4", "2")}</lem><rdg>#{mei_note("D4", "2")}</rdg></app>)
      choice = %(<choice><sic>#{mei_note("E4", "2")}</sic><corr>#{mei_note("F4", "2")}</corr></choice>)
      layer = app + choice + %(<del>#{mei_note("G4", "2")}</del>)
      expect(events(mei_staff(1, layer))).to eq ["half C4 at 1:1:000", "half F4 at 1:3:000"]
    end
  end

  describe "what the reader skips" do
    let(:notes) do
      attributes = %( stem.dir="up" stem.len="7" stem.mod="1slash" place="above" curvedir="above" dur.ges="1")
      mei_note("C4", "2", "xml:id": "n1") + %(<barLine form="dbl"/>) + mei_note("E4", "2", "xml:id": "n2").sub("/>", "#{attributes}/>")
    end

    let(:controls) do
      spans = %w[fing harm pedal octave breath bend arpeg gliss lv anchoredText annot dir].map do |name|
        %(<#{name} staff="1" tstamp="1" startid="#n1" endid="#n2">x</#{name}>)
      end
      [*spans, %(<harm staff="1" tstamp="1"><fb><f>6</f></fb></harm>), %(<tempo staff="1" tstamp="1">Andante</tempo>)].join
    end

    let(:flow) do
      xml = mei_document(%(<pb/>), mei_staff(1, notes) + controls, %(<sb/>), %(<expansion plist="#s1 #s1"/>), mei_staff(1, mei_note("G4", "1")))
      described_class.parse(xml.sub("<music>", %(<facsimile><surface><zone/></surface></facsimile><music>)).sub("<section>", %(<section><pgHead><rend>Head</rend></pgHead><pgFoot/>)))
    end

    it "keeps the music whole, as written, with none of the elements and attributes it has no place for" do
      part = flow.parts.first
      expect([flow.voices.first.voice_events.map(&:to_s), flow.tempo_changes, part.spans + flow.voices.first.spans, part.dynamic_events])
        .to eq [["half C4 at 1:1:000", "half E4 at 1:3:000", "whole G4 at 2:1:000"], {}, [], []]
      expect_mei_music_whole(flow)
    end
  end
end
