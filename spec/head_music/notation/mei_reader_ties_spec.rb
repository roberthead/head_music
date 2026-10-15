require "spec_helper"

describe HeadMusic::Notation::MEI do
  def parse(*items, **options)
    described_class.parse(mei_document(*items, **options))
  end

  def events(*items, voice: 0, **options)
    parse(*items, **options).voices[voice].voice_events.map(&:to_s)
  end

  def tied_bars(first_tie, last_tie, controls: "")
    [
      mei_staff(1, mei_note("C4", "2") + mei_note("E4", "2", tie: first_tie, "xml:id": "e1")) + controls,
      mei_staff(1, mei_note("E4", "2", tie: last_tie, "xml:id": "e2") + mei_note("D4", "2"))
    ]
  end

  let(:folded) { ["half C4 at 1:1:000", "half tied to half E4 at 1:3:000", "half D4 at 2:3:000"] }
  let(:unfolded) { ["half C4 at 1:1:000", "half E4 at 1:3:000", "half E4 at 2:1:000", "half D4 at 2:3:000"] }

  describe "@tie" do
    it "folds i and t across a barline" do
      expect(events(*tied_bars("i", "t"))).to eq folded
    end

    it "chains through m" do
      bars = [mei_staff(1, mei_note("C4", "2", tie: "i") + mei_note("C4", "2", tie: "m")), mei_staff(1, mei_note("C4", "1", tie: "t"))]
      expect(events(*bars)).to eq ["half tied to half tied to whole C4 at 1:1:000"]
    end

    it "ties every note of a chord that carries it" do
      chord = ->(tie) { %(<chord dur="1" tie="#{tie}">#{mei_note("C4") + mei_note("E4")}</chord>) }
      expect(events(mei_staff(1, chord.call("i")), mei_staff(1, chord.call("t")))).to eq ["whole tied to whole C4 E4 at 1:1:000"]
    end

    it "drops a tie that nothing ends, keeping the note's written value" do
      expect([events(*tied_bars("i", "t")), events(*tied_bars("i", nil))]).to eq [folded, unfolded]
    end

    it "drops a tie whose ends are in different voices" do
      upper = mei_note("C5", "2", tie: "i") + mei_note("C5", "4", tie: "t") + mei_note("E4", "4", tie: "i")
      bars = [mei_staff(1, [1, upper], [2, mei_note("C4", "1")]), mei_staff(1, [1, mei_note("G4", "1")], [2, mei_note("E4", "1", tie: "t")])]
      expect([events(*bars), events(*bars, voice: 1)])
        .to eq [["half tied to quarter C5 at 1:1:000", "quarter E4 at 1:4:000", "whole G4 at 2:1:000"], ["whole C4 at 1:1:000", "whole E4 at 2:1:000"]]
    end

    it "ties a grace note into its main note" do
      bar = %(<note pname="d" oct="4" dur="16" grace="unacc" tie="i"/>) + mei_note("D4", "1", tie: "t")
      grace = parse(mei_staff(1, bar)).voices.first.voice_events.first.grace_notes.first
      expect(grace).to be_tied
    end
  end

  describe "<tie>" do
    it "folds a tie by @startid and @endid" do
      expect(events(*tied_bars(nil, nil, controls: %(<tie startid="#e1" endid="#e2" staff="1"/>)))).to eq folded
    end

    it "folds a tie by @tstamp and @tstamp2, within 1/1000 beat of the onsets" do
      expect(events(*tied_bars(nil, nil, controls: %(<tie staff="1" tstamp="3.0004" tstamp2="1m+0.9995"/>)))).to eq folded
    end

    it "lets ids win over beats" do
      expect(events(*tied_bars(nil, nil, controls: %(<tie startid="#e1" endid="#e2" staff="1" tstamp="1" tstamp2="1m+3"/>)))).to eq folded
    end

    it "ties only the pitches two chords share by beats" do
      bars = [
        mei_staff(1, %(<chord dur="1">#{mei_note("C4") + mei_note("E4")}</chord>)) + %(<tie staff="1" tstamp="1" tstamp2="1m+1"/>),
        mei_staff(1, %(<chord dur="1">#{mei_note("C4") + mei_note("E4")}</chord>))
      ]
      expect(events(*bars)).to eq ["whole tied to whole C4 E4 at 1:1:000"]
    end

    it "skips a tie on some pitches of a chord, striking them again" do
      chord = ->(id) { %(<chord dur="1">#{mei_note("C4", nil, "xml:id": "#{id}c") + mei_note("E4", nil, "xml:id": "#{id}e")}</chord>) }
      tied = ->(*pitches) { [mei_staff(1, chord.call("a")) + pitches.map { |pitch| %(<tie startid="#a#{pitch}" endid="#b#{pitch}"/>) }.join, mei_staff(1, chord.call("b"))] }
      expect([events(*tied.call("c", "e")), events(*tied.call("c"))])
        .to eq [["whole tied to whole C4 E4 at 1:1:000"], ["whole C4 E4 at 1:1:000", "whole C4 E4 at 2:1:000"]]
    end

    def tied_by(control)
      events(*tied_bars(nil, nil, controls: control))
    end

    it "drops a tie by beats where no note starts" do
      expect([tied_by(%(<tie staff="1" tstamp="3" tstamp2="1m+1"/>)), tied_by(%(<tie staff="1" tstamp="2" tstamp2="1m+1"/>))])
        .to eq [folded, unfolded]
    end

    it "skips a tie in a reading the editorial rule rejects" do
      tie = %(<tie startid="#e1" endid="#e2"/>)
      expect([tied_by(%(<app><lem>#{tie}</lem><rdg/></app>)), tied_by(%(<app><lem/><rdg>#{tie}</rdg></app>))]).to eq [folded, unfolded]
    end

    it "never reads <lv>" do
      expect([tied_by(%(<tie startid="#e1" endid="#e2"/>)), tied_by(%(<lv startid="#e1" endid="#e2"/>))]).to eq [folded, unfolded]
    end

    it "raises on a tie between pitches that share nothing" do
      bars = tied_bars(nil, nil, controls: %(<tie startid="#e1" endid="#d1"/>))
      bars[1] = mei_staff(1, mei_note("F4", "2", "xml:id": "d1") + mei_note("D4", "2"))
      expect { parse(*bars) }.to raise_error(described_class::ParseError, /A tie connects E4 to F4 \(measure 1/)
    end

    it "refuses one that names an xml:id used twice" do
      bars = tied_bars(nil, nil, controls: %(<tie startid="#e1" endid="#e2"/>))
      bars[1] += %(<dir xml:id="e2">x</dir>)
      expect { parse(*bars) }.to raise_error(described_class::ParseError, /"e2" that a reference names is used twice/)
    end
  end

  describe "a tie's later note" do
    def sharp_tied(first, last, controls: "")
      [
        mei_staff(1, mei_note("C4", "2") + mei_note("F#4", "2", tie: first, "xml:id": "f1")) + controls,
        mei_staff(1, mei_note("F4", "2", tie: last, accid: nil, "xml:id": "f2") + mei_note("F4", "2", accid: nil))
      ]
    end

    it "takes its chain's alteration where it writes none, by @tie" do
      expect(events(*sharp_tied("i", "t")).drop(1)).to eq ["half tied to half F♯4 at 1:3:000", "half F4 at 2:3:000"]
    end

    it "takes its chain's alteration over one it writes, as encoders derive a tied note's @accid.ges from the key" do
      bar = mei_note("D5", "2", accid: "n", tie: "i") + mei_note("D5", "2", accid: nil, accid_ges: "f", tie: "t")
      expect(events(mei_staff(1, bar), score_def: mei_score_def(keysig: "5f"))).to eq ["half tied to half D5 at 1:1:000"]
    end

    it "takes its chain's alteration where it writes none, by <tie>" do
      expect(events(*sharp_tied(nil, nil, controls: %(<tie startid="#f1" endid="#f2"/>))).drop(1))
        .to eq ["half tied to half F♯4 at 1:3:000", "half F4 at 2:3:000"]
    end
  end
end
