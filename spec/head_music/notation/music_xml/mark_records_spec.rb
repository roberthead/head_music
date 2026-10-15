require "spec_helper"

describe HeadMusic::Notation::MusicXML::MarkRecords do
  let(:recorder) do
    Class.new(HeadMusic::Notation::MusicXML::MarkReader) do
      class << self
        attr_accessor :calls
      end

      def note(record)
        self.class.calls << [:note, record]
      end

      def direction(record)
        self.class.calls << [:direction, record]
      end

      def barline(record)
        self.class.calls << [:barline, record]
      end

      def apply(flow)
        self.class.calls << [:apply, flow.voices.map { |voice| voice.tuplets.length }]
      end
    end.tap { |klass| klass.calls = [] }
  end
  let(:attributes) { opening_attributes(divisions: 3) }

  def read(xml)
    stub_const("HeadMusic::Notation::MusicXML::MARK_READERS", [recorder])
    HeadMusic::Notation::MusicXML.parse(xml)
    recorder.calls
  end

  def records(xml, kind = :note)
    read(xml).filter_map { |hook, record| record if hook == kind }
  end

  def triplet(pitch, tuplet = nil)
    note_xml(pitch, 1, "eighth", after: "<time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification>",
      notations: tuplet ? %(<tuplet type="#{tuplet}"/>) : "")
  end

  it "registers a mark reader of each kind" do
    expect(HeadMusic::Notation::MusicXML::MARK_READERS).to all(be < HeadMusic::Notation::MusicXML::MarkReader)
  end

  describe "note records" do
    let(:xml) do
      musicxml_measures(
        triplet("C4", "start") + triplet("D4") + triplet("E4", "stop") +
          note_xml("G4", 3, "quarter") + note_xml("B4", 3, "quarter", chord: true) +
          note_xml("A4", 6, "half", inside: %(<tie type="start"/>)),
        "<note><grace/>#{pitch_xml("B4")}<type>16th</type></note>" + note_xml("A4", 3, "quarter", inside: %(<tie type="stop"/>)) +
          "<note><grace/>#{pitch_xml("D5")}<type>16th</type></note>" + rest_xml(3, "quarter") + note_xml("C5", 6, "half"),
        measure_rest_xml(12),
        attributes: attributes
      )
    end
    let(:notes) { records(xml) }

    it "comes in document order, one to each <note>, with its element" do
      expect(notes.map { |record| record.element.elements["pitch/step"]&.text }).to eq %w[C D E G B A B A D] + [nil, "C", nil]
    end

    it "gives each its exact onset in its bar" do
      expect(notes.first(4).map(&:onset)).to eq [0, Rational(1, 12), Rational(1, 6), Rational(1, 4)]
    end

    it "gives a chord tone its chord" do
      chord = notes[4]
      expect([chord.chord?, chord.voice_event.pitches.map(&:to_s)]).to eq [true, %w[G4 B4]]
    end

    it "gives a tie's later link the event its chain began with, at its own onset" do
      later = notes[7]
      expect([later.continuation?, later.voice_event.equal?(notes[5].voice_event), later.bar_number, later.onset]).to eq [true, true, 2, 0]
    end

    it "gives a grace note before a tie's later link no grace index" do
      expect([notes[6].grace?, notes[6].grace_index]).to eq [true, nil]
    end

    it "gives a dropped grace note the rest it led to" do
      expect([notes[8].grace_index, notes[8].voice_event.rest?]).to eq [nil, true]
    end

    it "gives a whole-measure rest the rest filling its bar" do
      expect(notes.last.voice_event.to_s).to eq "whole rest at 3:1:000"
    end

    it "names the part and voice" do
      expect([notes.first.part, notes.first.voice]).to eq [notes.first.voice.part, notes.first.voice_event.voice]
    end

    it "names the measure" do
      expect(notes.map(&:measure).uniq).to eq %w[1 2 3]
    end
  end

  it "gives a grace note that is kept its index" do
    xml = musicxml_measures("<note><grace/>#{pitch_xml("D5")}<type>16th</type></note>" + note_xml("C5", 4, "whole"))
    grace = records(xml).first
    expect([grace.grace?, grace.grace_index, grace.voice_event.grace_notes.length]).to eq [true, 0, 1]
  end

  it "numbers bars from a pickup's bar 0" do
    xml = musicxml_measures([note_xml("G4", 1, "quarter"), {number: "0", implicit: true}], note_xml("C5", 4, "whole"))
    expect(records(xml).map { |record| [record.bar_number, record.onset] }).to eq [[0, Rational(3, 4)], [1, 0]]
  end

  describe "direction records" do
    let(:direction) { %(<direction><direction-type><dynamics><f/></dynamics></direction-type><offset>1</offset><voice>2</voice></direction>) }
    let(:record) do
      records(musicxml_measures(note_xml("C4", 3, "half", dots: 1, voice: "2") + direction + note_xml("D4", 1, "quarter", voice: "2")), :direction).first
    end

    it "carries the cursor before any offset" do
      expect(record.cursor).to eq Rational(3, 4)
    end

    it "carries the divisions in force" do
      expect(record.divisions).to eq 1
    end

    it "finds the part's voice for a <voice> value" do
      expect([record.voice_for("2"), record.voice_for("9")]).to eq [record.part.voices.first, nil]
    end

    it "is made for a <sound> written straight in a measure" do
      xml = musicxml_measures(%(<sound tempo="90"/>) + note_xml("C4", 4, "whole"))
      expect(records(xml, :direction).map { |sound| sound.element.name }).to eq ["sound"]
    end

    it "counts the first half of a split bar into the cursor" do
      xml = musicxml_measures(note_xml("C4", 4, "whole"), note_xml("D4", 1, "quarter"), [direction.sub("<voice>2</voice>", "") + note_xml("E4", 3, "half", dots: 1), {implicit: true}])
      expect(records(xml, :direction).first.cursor).to eq Rational(1, 4)
    end
  end

  describe "barline records" do
    let(:repeat) { %(<barline location="right"><bar-style>light-heavy</bar-style><repeat direction="backward"/></barline>) }
    let(:barlines) do
      records(musicxml_measures(note_xml("C4", 4, "whole"), note_xml("D4", 1, "quarter") + repeat, [note_xml("E4", 3, "half", dots: 1) + repeat, {implicit: true}]), :barline)
    end

    it "says a barline inside a split bar is mid-bar" do
      expect(barlines.map(&:mid_bar?)).to eq [true, false]
    end

    it "says which is in the last bar" do
      expect(barlines.map { |barline| [barline.bar_number, barline.last?] }).to eq [[2, true], [2, true]]
    end
  end

  it "applies once, after every record, with the voices final" do
    xml = musicxml_measures(triplet("C4", "start") + triplet("D4") + triplet("E4", "stop") + note_xml("G4", 9, "half", dots: 1), attributes: attributes)
    expect(read(xml).last).to eq [:apply, [1]]
  end
end
