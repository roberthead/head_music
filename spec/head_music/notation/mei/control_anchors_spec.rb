require "spec_helper"

describe HeadMusic::Notation::MEI::ControlAnchors do
  def recorded(*items, **options)
    MEIMarkRecorder.parse(mei_document(*items, **options))
  end

  def controls(*items, **options)
    recorded(*items, **options).of(HeadMusic::Notation::MEI::ControlRecord)
  end

  def control(xml, *later, layers: nil)
    first = layers ? mei_staff(1, *layers) : mei_staff(1, mei_note("C4", "4", "xml:id": "c") + mei_note("D4", "4", "xml:id": "d") + mei_note("E4", "2", "xml:id": "e"))
    controls(first + xml, *later).first
  end

  def ends(record)
    [record.start, record.finish].map { |anchor| anchor && [anchor.position.to_s, anchor.voice_event&.to_s] }
  end

  let(:second_bar) { mei_staff(1, mei_note("F4", "1", "xml:id": "f")) }

  describe "by ids" do
    it "anchors each end at the event it names" do
      expect(ends(control(%(<slur startid="#c" endid="#f"/>), second_bar))).to eq [["1:1:000", "quarter C4 at 1:1:000"], ["2:1:000", "whole F4 at 2:1:000"]]
    end

    it "lets ids win over beats" do
      expect(ends(control(%(<slur staff="1" startid="#d" tstamp="1" endid="#e" tstamp2="0m+2"/>)))).to eq [["1:2:000", "quarter D4 at 1:2:000"], ["1:3:000", "half E4 at 1:3:000"]]
    end

    it "anchors at the record of the event, a chord tone's being the chord's position" do
      layer = %(<chord dur="1">#{mei_note("C4", nil, "xml:id": "t1") + mei_note("E4", nil, "xml:id": "t2")}</chord>)
      record = control(%(<dynam startid="#t2">p</dynam>), layers: [[1, layer]])
      expect([record.start.record.chord_member?, record.start.position.to_s, record.start.event?]).to eq [true, "1:1:000", true]
    end

    it "lists the anchors its @plist names" do
      expect(control(%(<beamSpan plist="#c #d" startid="#c" endid="#d"/>)).plist.map { |anchor| anchor.voice_event.to_s })
        .to eq ["quarter C4 at 1:1:000", "quarter D4 at 1:2:000"]
    end

    it "skips a control naming an id in a reading the editorial rule rejects, or in another file" do
      layer = %(<app><lem>#{mei_note("C4", "1", "xml:id": "lem")}</lem><rdg>#{mei_note("D4", "1", "xml:id": "rdg")}</rdg></app>)
      controls = controls(mei_staff(1, layer) + %(<dir startid="#rdg">a</dir><dir startid="other.mei#lem">b</dir><dir startid="#lem">c</dir>))
      expect(controls.map { |record| record.element.text }).to eq ["c"]
    end

    it "raises on an id that names no element, naming the control" do
      expect { control(%(<slur startid="#c" endid="#nothing"/>)) }.to raise_error(HeadMusic::Notation::MEI::ParseError, /"nothing" names no element \(measure 1, <slur>\)/)
    end
  end

  describe "by beats" do
    it "snaps a @tstamp within 1/1000 beat of an onset in the layer its @layer names, else the staff's first" do
      layers = [[1, mei_note("C5", "4") + mei_note("D5", "2", dots: "1")], [2, mei_note("C4", "4") + mei_note("D4", "2", dots: "1")]]
      records = controls(mei_staff(1, *layers) + %(<dynam staff="1" layer="2" tstamp="1.9996">p</dynam><dynam staff="1" tstamp="2.0004">f</dynam>))
      expect(records.map { |record| ends(record).first }).to eq [["1:2:000", "dotted half D4 at 1:2:000"], ["1:2:000", "dotted half D5 at 1:2:000"]]
    end

    it "snaps on its staff where its layer has no onset there" do
      layers = [[1, mei_note("C5", "2") + mei_note("D5", "2")], [2, mei_note("C4", "1")]]
      expect(ends(control(%(<dynam staff="1" layer="2" tstamp="3.0004">p</dynam>), layers: layers)).first).to eq ["1:3:000", "half D5 at 1:3:000"]
    end

    it "rounds to the tick where no onset is near" do
      record = control(%(<dynam staff="1" tstamp="2.5">p</dynam>))
      expect([ends(record).first, record.start.event?]).to eq [["1:2:480", nil], false]
    end

    it "rounds a beat written to four places, such as a triplet's 1.6667, to the tick and not past it" do
      expect(ends(control(%(<dynam staff="1" tstamp="1.6667">p</dynam>))).first).to eq ["1:1:640", nil]
    end

    it "takes a beat before the first, as 0 or 0.5, as the downbeat" do
      expect([ends(control(%(<slur staff="1" tstamp="0" tstamp2="1m+0.5"/>), second_bar)), ends(control(%(<dynam staff="1" tstamp="0.5">p</dynam>))).first])
        .to eq [[["1:1:000", "quarter C4 at 1:1:000"], ["2:1:000", "whole F4 at 2:1:000"]], ["1:1:000", "quarter C4 at 1:1:000"]]
    end

    it "reads a @tstamp2 one past the last bar's count as the final barline" do
      expect(ends(control(%(<hairpin form="cres" staff="1" tstamp="1" tstamp2="1m+5"/>), second_bar)).last).to eq ["3:1:000", nil]
    end

    it "reads a beat after the music ends in a short last bar as that beat, not the final barline" do
      short_bar = %(<measure n="2" metcon="false">#{mei_staff(1, mei_note("F4", "2", dots: "1"))}</measure>)
      expect(ends(control(%(<hairpin form="cres" staff="1" tstamp="1" tstamp2="1m+4"/>), short_bar)).last).to eq ["2:4:000", nil]
    end

    it "counts the measures a @tstamp2 reaches" do
      expect(ends(control(%(<hairpin form="cres" staff="1" tstamp="1" tstamp2="1m+1"/>), second_bar)).last).to eq ["2:1:000", "whole F4 at 2:1:000"]
    end

    it "has no finish for a @tstamp2 with no measure part" do
      expect(control(%(<hairpin form="cres" staff="1" tstamp="1" tstamp2="3"/>)).finish).to be_nil
    end

    it "drops an end whose beat is past its measure or past the music, as excerpts' spans reach" do
      expect([control(%(<slur staff="1" tstamp="6" tstamp2="0m+2"/>)).start, control(%(<slur staff="1" tstamp="1" tstamp2="3m+1"/>), second_bar).finish])
        .to eq [nil, nil]
    end

    it "raises on a beat no measure could hold" do
      expect { control(%(<slur staff="1" tstamp="1" tstamp2="99999m+1"/>)) }.to raise_error(HeadMusic::Notation::MEI::ParseError, /Unreadable @tstamp2/)
    end

    it "has no finish for a span by beats that ends before it starts" do
      expect(control(%(<hairpin form="cres" staff="1" tstamp="3" tstamp2="0m+1"/>)).finish).to be_nil
    end
  end

  describe "the part and voice" do
    let(:score_def) { mei_score_def(clefs: [%w[G 2], %w[F 4]]) }
    let(:staves) { mei_staff(1, mei_note("C5", "1")) + mei_staff(2, mei_note("C3", "1")) }

    it "takes the part of the first staff of a @staff list" do
      flow_controls = controls(staves + %(<dynam staff="2 1" tstamp="1">p</dynam>), score_def: score_def)
      expect(flow_controls.first.part.voices.first.voice_events.first.to_s).to eq "whole C3 at 1:1:000"
    end

    it "names a voice only where @layer is given" do
      records = controls(staves + %(<dynam staff="1" tstamp="1">p</dynam><dynam staff="1" layer="1" tstamp="1">f</dynam>), score_def: score_def)
      expect(records.map { |record| record.voice&.voice_events&.first&.to_s }).to eq [nil, "whole C5 at 1:1:000"]
    end
  end

  describe "the readers' helpers" do
    let(:recorder) { recorded(mei_staff(1, mei_note("C4", "1", "xml:id": "c")) + %(<slur staff="1" tstamp="1" tstamp2="0m+5"/>)) }

    it "finds the notes that start where an anchor is" do
      start = recorder.of(HeadMusic::Notation::MEI::ControlRecord).first.start
      expect(recorder.anchors.notes_starting_at(start).map { |record| record.voice_event.to_s }).to eq ["whole C4 at 1:1:000"]
    end

    it "names the containers an event is inside, outermost first, through editorial markup" do
      layer = %(<beam xml:id="b"><app><lem><tuplet xml:id="t" num="3" numbase="2">#{mei_note("C4", "8") * 3}</tuplet></lem></app></beam>) + mei_note("D4", "2", dots: "1")
      recorder = recorded(mei_staff(1, layer))
      records = recorder.of(HeadMusic::Notation::MEI::EventRecord)
      expect(records.map { |record| recorder.anchors.containers(record).map { |element| element.attributes["xml:id"] } }).to eq [%w[b t], %w[b t], %w[b t], []]
    end

    it "reads an element's children through the editorial rule" do
      note = REXML::Document.new(%(<note><app><lem><artic artic="stacc"/></lem><rdg><artic artic="acc"/></rdg></app></note>)).root
      expect(recorder.anchors.children(note).map { |child| child.attributes["artic"] }).to eq ["stacc"]
    end
  end
end
