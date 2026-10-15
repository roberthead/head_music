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
      def voices(*items)
        parse(*items, score_def: mei_score_def(clefs: [%w[G 2], %w[F 4]])).voices.map { |voice| voice.voice_events.map(&:to_s) }
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

      it "raises where no other layer in the measure gives a length" do
        expect { parse(mei_staff(1, %(<space/>) + mei_note("C4"))) }
          .to raise_error(described_class::ParseError, /A <space> with no @dur has no other layer in its measure to take its length from \(measure 1, <space>\)/)
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

    it "raises on a chord of no notes" do
      expect { parse(mei_staff(1, %(<chord dur="1"/>))) }.to raise_error(described_class::ParseError, /<chord> has no <note>/)
    end
  end

  describe "grace notes" do
    def graces(*items)
      parse(*items).voices.first.voice_events.flat_map { |event| event.grace_notes.map(&:to_s) }
    end

    it "reads @grace, slashed where it is acc" do
      expect(graces(mei_staff(1, mei_note("D4", "8", grace: "acc") + mei_note("E4", "16", grace: "unacc") + mei_note("C4", "1"))))
        .to eq ["slashed grace eighth D4", "grace sixteenth E4"]
    end

    it "reads a <graceGrp>, an eighth where no @dur is given" do
      expect(graces(mei_staff(1, %(<graceGrp grace="acc"><note pname="d" oct="4"/></graceGrp>) + mei_note("C4", "1"))))
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
end
